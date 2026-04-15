from flask import Flask, request, jsonify, session, send_from_directory
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
import sqlite3
import os

app = Flask(__name__, static_folder='static')
app.secret_key = 'flashcard_demo_key_2025'
CORS(app, supports_credentials=True)

DB_PATH = 'flashcards.db'


# ── Database helpers ──────────────────────────────────────────────────────────

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row   # lets us access columns by name
    conn.execute('PRAGMA foreign_keys = ON')
    return conn


def init_db():
    """Create tables from schema.sql if they don't exist yet."""
    conn = get_db()
    schema_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'schema.sql')
    with open(schema_path, 'r') as f:
        conn.executescript(f.read())
    conn.commit()
    conn.close()


# ── Auth decorator ────────────────────────────────────────────────────────────

def login_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': 'Please log in first'}), 401
        return f(*args, **kwargs)
    return wrapper


# ── Serve frontend ────────────────────────────────────────────────────────────

@app.route('/')
def index():
    return send_from_directory('static', 'index.html')


# ── Auth routes ───────────────────────────────────────────────────────────────

@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    username = (data.get('username') or '').strip()
    email    = (data.get('email')    or '').strip()
    password = (data.get('password') or '')

    if not username or not email or not password:
        return jsonify({'error': 'All fields are required'}), 400

    if len(password) < 4:
        return jsonify({'error': 'Password must be at least 4 characters'}), 400

    hashed = generate_password_hash(password)

    try:
        conn = get_db()
        conn.execute(
            'INSERT INTO user (username, email, password) VALUES (?, ?, ?)',
            (username, email, hashed)
        )
        conn.commit()
        conn.close()
        return jsonify({'message': 'Account created! You can now log in.'}), 201
    except sqlite3.IntegrityError:
        return jsonify({'error': 'Username or email is already taken'}), 409


@app.route('/api/login', methods=['POST'])
def login():
    data     = request.json
    email    = (data.get('email')    or '').strip()
    password = (data.get('password') or '')

    conn = get_db()
    user = conn.execute(
        'SELECT * FROM user WHERE email = ?', (email,)
    ).fetchone()
    conn.close()

    if not user or not check_password_hash(user['password'], password):
        return jsonify({'error': 'Wrong email or password'}), 401

    # save user info in session
    session['user_id']  = user['user_id']
    session['username'] = user['username']
    return jsonify({'message': 'Logged in', 'username': user['username']})


@app.route('/api/logout', methods=['POST'])
def logout():
    session.clear()
    return jsonify({'message': 'Logged out'})


@app.route('/api/me')
def me():
    if 'user_id' not in session:
        return jsonify({'logged_in': False})
    return jsonify({'logged_in': True, 'username': session['username']})


# ── Deck routes ───────────────────────────────────────────────────────────────

@app.route('/api/decks', methods=['GET'])
@login_required
def get_decks():
    conn  = get_db()
    decks = conn.execute(
        'SELECT * FROM deck WHERE user_id = ? ORDER BY created_at DESC',
        (session['user_id'],)
    ).fetchall()

    result = []
    for d in decks:
        count = conn.execute(
            'SELECT COUNT(*) as cnt FROM flashcard WHERE deck_id = ?',
            (d['deck_id'],)
        ).fetchone()['cnt']
        result.append({
            'id':          d['deck_id'],
            'name':        d['deck_name'],
            'description': d['description'] or '',
            'color':       d['color'] or '#2563eb',
            'card_count':  count,
            'tags':        []   # tags not in schema yet, keeping it empty for now
        })
    conn.close()
    return jsonify(result)


@app.route('/api/decks', methods=['POST'])
@login_required
def create_deck():
    data = request.json
    name = (data.get('name') or '').strip()

    if not name:
        return jsonify({'error': 'Deck name is required'}), 400

    conn = get_db()
    cur  = conn.execute(
        'INSERT INTO deck (user_id, deck_name, description, color) VALUES (?, ?, ?, ?)',
        (session['user_id'], name, data.get('description', ''), data.get('color', '#2563eb'))
    )
    conn.commit()
    new_id = cur.lastrowid
    conn.close()

    return jsonify({'id': new_id, 'name': name, 'card_count': 0, 'tags': [],
                    'description': data.get('description', ''),
                    'color': data.get('color', '#2563eb')}), 201


@app.route('/api/decks/<int:deck_id>', methods=['PUT'])
@login_required
def update_deck(deck_id):
    conn = get_db()
    deck = conn.execute(
        'SELECT * FROM deck WHERE deck_id = ? AND user_id = ?',
        (deck_id, session['user_id'])
    ).fetchone()

    if not deck:
        conn.close()
        return jsonify({'error': 'Deck not found'}), 404

    data = request.json
    conn.execute(
        'UPDATE deck SET deck_name=?, description=?, color=? WHERE deck_id=?',
        (data.get('name', deck['deck_name']),
         data.get('description', deck['description']),
         data.get('color', deck['color']),
         deck_id)
    )
    conn.commit()
    conn.close()
    return jsonify({'message': 'Deck updated'})


@app.route('/api/decks/<int:deck_id>', methods=['DELETE'])
@login_required
def delete_deck(deck_id):
    conn = get_db()
    deck = conn.execute(
        'SELECT * FROM deck WHERE deck_id = ? AND user_id = ?',
        (deck_id, session['user_id'])
    ).fetchone()

    if not deck:
        conn.close()
        return jsonify({'error': 'Deck not found'}), 404

    # cascade handles the flashcards (PRAGMA foreign_keys = ON)
    conn.execute('DELETE FROM deck WHERE deck_id = ?', (deck_id,))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Deck deleted'})


# ── Card routes ───────────────────────────────────────────────────────────────

@app.route('/api/decks/<int:deck_id>/cards', methods=['GET'])
@login_required
def get_cards(deck_id):
    conn = get_db()
    # make sure the deck belongs to this user
    deck = conn.execute(
        'SELECT * FROM deck WHERE deck_id = ? AND user_id = ?',
        (deck_id, session['user_id'])
    ).fetchone()

    if not deck:
        conn.close()
        return jsonify({'error': 'Deck not found'}), 404

    cards = conn.execute(
        'SELECT * FROM flashcard WHERE deck_id = ? ORDER BY created_at',
        (deck_id,)
    ).fetchall()
    conn.close()

    return jsonify([{
        'id':    c['flashcard_id'],
        'front': c['front_text'],
        'back':  c['back_text'],
        'hint':  c['hint'] or ''
    } for c in cards])


@app.route('/api/decks/<int:deck_id>/cards', methods=['POST'])
@login_required
def create_card(deck_id):
    conn = get_db()
    deck = conn.execute(
        'SELECT * FROM deck WHERE deck_id = ? AND user_id = ?',
        (deck_id, session['user_id'])
    ).fetchone()

    if not deck:
        conn.close()
        return jsonify({'error': 'Deck not found'}), 404

    data  = request.json
    front = (data.get('front') or '').strip()
    back  = (data.get('back')  or '').strip()

    if not front or not back:
        return jsonify({'error': 'Front and back text are required'}), 400

    cur = conn.execute(
        'INSERT INTO flashcard (deck_id, front_text, back_text, hint) VALUES (?, ?, ?, ?)',
        (deck_id, front, back, data.get('hint', ''))
    )
    conn.commit()
    new_id = cur.lastrowid
    conn.close()

    return jsonify({'id': new_id, 'front': front, 'back': back,
                    'hint': data.get('hint', '')}), 201


@app.route('/api/cards/<int:card_id>', methods=['PUT'])
@login_required
def update_card(card_id):
    conn = get_db()
    # join with deck to verify ownership
    card = conn.execute('''
        SELECT f.* FROM flashcard f
        JOIN deck d ON f.deck_id = d.deck_id
        WHERE f.flashcard_id = ? AND d.user_id = ?
    ''', (card_id, session['user_id'])).fetchone()

    if not card:
        conn.close()
        return jsonify({'error': 'Card not found'}), 404

    data = request.json
    conn.execute(
        'UPDATE flashcard SET front_text=?, back_text=?, hint=? WHERE flashcard_id=?',
        (data.get('front', card['front_text']),
         data.get('back',  card['back_text']),
         data.get('hint',  card['hint']),
         card_id)
    )
    conn.commit()
    conn.close()
    return jsonify({'message': 'Card updated'})


@app.route('/api/cards/<int:card_id>', methods=['DELETE'])
@login_required
def delete_card(card_id):
    conn = get_db()
    card = conn.execute('''
        SELECT f.* FROM flashcard f
        JOIN deck d ON f.deck_id = d.deck_id
        WHERE f.flashcard_id = ? AND d.user_id = ?
    ''', (card_id, session['user_id'])).fetchone()

    if not card:
        conn.close()
        return jsonify({'error': 'Card not found'}), 404

    conn.execute('DELETE FROM flashcard WHERE flashcard_id = ?', (card_id,))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Card deleted'})


# ── Start ─────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    init_db()
    port = int(os.environ.get('PORT', 5001))
    print(f'\n  Flashcard app running → http://localhost:{port}\n')
    app.run(debug=True, port=port)

from flask import Flask, request, jsonify
import requests, sqlite3

app = Flask(__name__)
DB_PATH = './files/www/users.db'

def users_exist():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM users")
    count = cursor.fetchone()[0]
    conn.close()
    return count > 0

@app.route('/create_service', methods=['POST'])
def create_service():
    if not users_exist():
        return jsonify({"error": "Aucun utilisateur enregistré"}), 400
    data = request.json 
    message = data.get('message')
    user_id = data.get('userId')

    try:
        response = requests.post(
            'http://localhost:5001/action',
            json={'message': message, 'userId': user_id}
        )
        result = response.json()
        return jsonify({'success': True, 'resultat': result})
    except Exception as e:
        return jsonify({'success': False, 'erreur': str(e)}), 500

if __name__ == '__main__':
    app.run(port=5000)

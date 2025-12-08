from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

@app.route('/send', methods=['POST'])
def send():
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

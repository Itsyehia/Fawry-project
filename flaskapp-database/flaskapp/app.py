from flask import Flask, render_template, json, request, redirect, session, url_for, jsonify
from flaskext.mysql import MySQL
import os

app = Flask(__name__)
app.secret_key = 'why_would_I_tell_you_my_secret'  # change for prod

mysql = MySQL()

# MySQL configurations (from env variables)
app.config['MYSQL_DATABASE_USER'] = os.getenv('MYSQL_DATABASE_USER')
app.config['MYSQL_DATABASE_PASSWORD'] = os.getenv('MYSQL_DATABASE_PASSWORD')
app.config['MYSQL_DATABASE_DB'] = os.getenv('MYSQL_DATABASE_DB')
app.config['MYSQL_DATABASE_HOST'] = os.getenv('MYSQL_DATABASE_HOST')

mysql.init_app(app)

# External prefix presented by ingress
BASE_PATH = "/flask"

# Make BASE_PATH available in Jinja templates (if you want to use it there)
@app.context_processor
def inject_base_path():
    return dict(BASE_PATH=BASE_PATH)

def redirect_with_base(endpoint, **values):
    """
    Build an app-internal URL with url_for, then prefix with BASE_PATH
    so the browser is redirected to /flask/... (what ingress exposes).
    """
    return redirect(BASE_PATH + url_for(endpoint, **values))

@app.route("/")
def main():
    return render_template('index.html')

@app.route('/showSignUp')
def showSignUp():
    return render_template('signup.html')

@app.route('/showSignIn')
def showSignIn():
    return render_template('signin.html')

@app.route('/signUp', methods=['POST'])
def signUp():
    conn, cursor = None, None
    try:
        _name = request.form.get('inputName')
        _email = request.form.get('inputEmail')
        _password = request.form.get('inputPassword')

        if _name and _email and _password:
            conn = mysql.connect()
            cursor = conn.cursor()
            cursor.callproc('sp_createUser', (_name, _email, _password))
            data = cursor.fetchall()

            if len(data) == 0:
                conn.commit()
                return jsonify({'message': 'User created successfully!'}), 200
            else:
                return jsonify({'error': str(data[0])}), 400
        else:
            return jsonify({'error': 'Enter all required fields'}), 400
    except Exception as e:
        print("signUp error:", str(e))  # log the error
        return jsonify({'error': str(e)}), 500
    finally:
        try:
            if cursor: cursor.close()
        except: pass
        try:
            if conn: conn.close()
        except: pass


@app.route('/validateLogin', methods=['POST'])
def validateLogin():
    conn, cursor = None, None
    try:
        _username = request.form['inputEmail']
        _password = request.form['inputPassword']

        conn = mysql.connect()
        cursor = conn.cursor()
        cursor.callproc('sp_validateLogin', (_username,))
        data = cursor.fetchall()

        if len(data) > 0 and data[0][3] == _password:
            session['user'] = data[0][0]
            return redirect_with_base('userHome')
        else:
            return render_template('error.html', error='Wrong Email address or Password')
    except Exception as e:
        print("validateLogin error:", str(e))
        return render_template('error.html', error=str(e))
    finally:
        try:
            if cursor: cursor.close()
        except: pass
        try:
            if conn: conn.close()
        except: pass

@app.route('/userHome')
def userHome():
    if session.get('user'):
        return render_template('userHome.html')
    else:
        return render_template('error.html', error='Unauthorized Access')

@app.route('/getWish')
def getWish():
    conn, cursor = None, None
    try:
        if session.get('user'):
            _user = session.get('user')
            conn = mysql.connect()
            cursor = conn.cursor()
            cursor.callproc('sp_GetWishByUser', (_user,))
            wishes = cursor.fetchall()

            wishes_dict = [
                {'Id': wish[0], 'Title': wish[1], 'Description': wish[2], 'Date': wish[4]}
                for wish in wishes
            ]
            return json.dumps(wishes_dict)
        else:
            return render_template('error.html', error='Unauthorized Access')
    except Exception as e:
        print("getWish error:", str(e))
        return render_template('error.html', error=str(e))
    finally:
        try:
            if cursor: cursor.close()
        except: pass
        try:
            if conn: conn.close()
        except: pass

@app.route('/addWish', methods=['POST'])
def addWish():
    conn, cursor = None, None
    try:
        if session.get('user'):
            _title = request.form['inputTitle']
            _description = request.form['inputDescription']
            _user = session.get('user')

            conn = mysql.connect()
            cursor = conn.cursor()
            cursor.callproc('sp_addWish', (_title, _description, _user))
            data = cursor.fetchall()

            if len(data) == 0:
                conn.commit()
                return redirect_with_base('userHome')
            else:
                return render_template('error.html', error='An error occurred!')
        else:
            return render_template('error.html', error='Unauthorized Access')
    except Exception as e:
        print("addWish error:", str(e))
        return render_template('error.html', error=str(e))
    finally:
        try:
            if cursor: cursor.close()
        except: pass
        try:
            if conn: conn.close()
        except: pass

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect_with_base('main')

@app.route('/healthz')
def healthz():
    return "ok", 200

@app.route('/readiness')
def readiness():
    # readiness check that includes database connectivity
    try:
        conn = mysql.connect()
        conn.close()
        return "ready", 200
    except Exception as e:
        return f"not ready: {str(e)}", 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002)

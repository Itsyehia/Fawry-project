import pytest
from unittest.mock import patch, MagicMock
from app import app


@pytest.fixture
def client():
    app.config['TESTING'] = True
    app.config['SECRET_KEY'] = "test_secret"
    with app.test_client() as client:
        yield client


def test_home_page(client):
    """GET / should return index.html"""
    response = client.get('/')
    assert response.status_code == 200


def test_show_signup_page(client):
    """GET /showSignUp should return signup.html"""
    response = client.get('/showSignUp')
    assert response.status_code == 200


def test_signup_missing_fields(client):
    """POST /signUp with missing data should return error page"""
    response = client.post('/signUp', data={})
    assert response.status_code == 400
    assert b"Enter the required fields" in response.data


@patch('app.mysql')
def test_signup_success(mock_mysql, client):
    """POST /signUp should create user when all fields are present"""
    mock_conn = MagicMock()
    mock_cursor = MagicMock()
    mock_mysql.connect.return_value = mock_conn
    mock_conn.cursor.return_value = mock_cursor
    mock_cursor.fetchall.return_value = []

    response = client.post('/signUp', data={
        'inputName': 'John',
        'inputEmail': 'john@example.com',
        'inputPassword': 'pass123'
    })

    assert response.status_code == 200
    assert b"User created successfully" in response.data


def test_show_signin_page(client):
    """GET /showSignIn should return signin.html"""
    response = client.get('/showSignIn')
    assert response.status_code == 200


@patch('app.mysql')
def test_validate_login_success(mock_mysql, client):
    """POST /validateLogin with correct password should redirect"""
    mock_conn = MagicMock()
    mock_cursor = MagicMock()
    mock_mysql.connect.return_value = mock_conn
    mock_conn.cursor.return_value = mock_cursor
    mock_cursor.fetchall.return_value = [
        (1, "John", "john@example.com", "pass123")]

    response = client.post('/validateLogin', data={
        'inputEmail': 'john@example.com',
        'inputPassword': 'pass123'
    }, follow_redirects=False)

    assert response.status_code == 302
    assert '/userHome' in response.headers['Location']


def test_user_home_unauthorized(client):
    """GET /userHome without session should return unauthorized"""
    response = client.get('/userHome')
    assert b"Unauthorized Access" in response.data

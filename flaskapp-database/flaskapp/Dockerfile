FROM python:3.6
WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt
EXPOSE 5002
CMD python -m flask run --host=0.0.0.0 --port=5002

# run the container
# docker rm -f flaskapp 2>$null; docker run -d --name flaskapp --network appnet -p 5002:5002 -e FLASK_APP=app.py -e MYSQL_DATABASE_USER=root -e MYSQL_DATABASE_PASSWORD=root -e MYSQL_DATABASE_DB=BucketList -e MYSQL_DATABASE_HOST=db flaskapp

# run new container 
# docker run -d --name flaskapp --network appnet -p 5002:5002 -e FLASK_APP=app.py -e MYSQL_DATABASE_USER=root -e MYSQL_DATABASE_PASSWORD=root -e MYSQL_DATABASE_DB=BucketList -e MYSQL_DATABASE_HOST=db bucketlist-flask:latest

# link http://testing.local/showSignUp
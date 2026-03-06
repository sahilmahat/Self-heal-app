FROM python:3.10-alpine

WORKDIR /app

COPY . .

RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python","app.py"]

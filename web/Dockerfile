FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
ENV FLASK_APP=app.py
ENV FLASK_ENV=development
ENV BASE_PATH=/app2

CMD ["python", "app.py"]

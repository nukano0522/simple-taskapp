FROM python:3.9

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
ENV FLASK_APP=app.py
ENV FLASK_ENV=development
CMD ["python", "app.py"]

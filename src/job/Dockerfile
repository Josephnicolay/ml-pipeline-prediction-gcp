FROM python:3.8

WORKDIR /app

COPY requirements.txt .
COPY main.py .


RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["python", "main.py"]

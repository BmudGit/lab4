from python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENV YOUR_NAME="friend"
EXPOSE 5500
CMD["python", "app.py"]
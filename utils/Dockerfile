FROM python:3-alpine
WORKDIR /app
COPY utils.py .
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN apk add --no-cache curl jq
ENTRYPOINT ["python", "utils.py"]

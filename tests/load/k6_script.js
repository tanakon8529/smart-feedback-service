import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 20 }, // Ramp up to 20 users
    { duration: '1m', target: 20 },  // Stay at 20 users
    { duration: '10s', target: 0 },  // Scale down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
  },
};

export default function () {
  const url = 'http://localhost:8000/api/v1/feedback';
  const payload = JSON.stringify({
    customer_id: `user_${__VU}`,
    message: 'This service is amazing and fast!',
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  let res = http.post(url, payload, params);

  check(res, {
    'is status 201': (r) => r.status === 201,
    'sentiment is correct': (r) => r.json('sentiment') === 'Positive',
  });

  sleep(1);
}

const https = require('https');

const token = process.env.MONDAY_API_TOKEN;
const boardId = '18411593067';

const query = `query {
  boards(ids: ${boardId}) {
    id
    name
    description
    items {
      id
      name
      state
      created_at
      updated_at
    }
  }
}`;

const options = {
  hostname: 'api.monday.com',
  path: '/graphql',
  method: 'POST',
  headers: {
    'Authorization': token,
    'Content-Type': 'application/json'
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    try {
      const result = JSON.parse(data);
      console.log(JSON.stringify(result, null, 2));
    } catch (e) {
      console.error('Error parsing response:', e);
      console.error('Raw response:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.write(JSON.stringify({ query }));
req.end();

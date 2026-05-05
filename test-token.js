const https = require('https');

const token = process.env.MONDAY_API_TOKEN;

if (!token) {
  console.error('No token provided');
  process.exit(1);
}

console.log('Token:', token.substring(0, 20) + '...');
console.log('Token length:', token.length);

const query = `query {
  me {
    id
    name
    email
  }
}`;

const options = {
  hostname: 'api.monday.com',
  path: '/graphql',
  method: 'POST',
  headers: {
    'Authorization': token,
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
};

const req = https.request(options, (res) => {
  let data = '';
  console.log('Status:', res.statusCode);
  console.log('Headers:', res.headers);

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('Response:', data);
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.write(JSON.stringify({ query }));
req.end();

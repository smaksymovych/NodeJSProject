
const express = require('express')
const app = express()
const port = process.env.PORT|| 3000;

app.get('/', (req, res) => {
  res.send('Hello World with Express!')
})

app.listen(port, () => {
  console.log(`Example app listening on http://127.0.0.1:${port}`)
})

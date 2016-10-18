# Post Office
## Hapi Email Server

[Post Office](https://www.npmjs.com/package/postoffice) is using couchbase with puffer library to register trigger points for emails and send emails to both list of subscribers and an email

* Source code is available at [here](https://github.com/rgmax/postoffice)

## How to use

You have to pass these variables to plugin.

```yaml
mail:
  api_key: your_mailgun_api_key
  domain: your_mailgun_domain
  from: My Name <my@email.address>
  mock: false
  lable: mail
  root: /path/to/templates/root
  trigger_events:
    event1_name:
      template: /path/to/template
      subject: event_mail_subject
    event2_name:
      template: /path/to/template
      subject: event_mail_subject
```

You should start a postoffice server in your code and also pass configuration to the postoffice server plugin:
```coffee
server.connection { port: Number(config.server.mail.port), labels: config.server.mail.label }

db = new require('puffer')(config.database)

server.register [ { register: require('postoffice'), options: { config: config.server.mail, database: db, url: config.url, scheme: config.scheme } } ], (err) -> throw err if err
```

## APIs
### POST /v1/trigger/{trigger_point}/subscribe
**payload { emails: ['email1', 'email2', ...] }**

### POST /v1/trigger/{trigger_point}/post
**payload { data: object, email: 'email_address' }**

### POST /v1/email/{email}/unsubscribe
**payload { trigger_points: [ 'trigger_point1', 'trigger_point2', ...] }**

### GET /v1/email/{email}/unsubscribe_list
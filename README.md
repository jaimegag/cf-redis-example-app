# CF Redis Example App

This Ruby based app is an example of how you can consume a Cloud Foundry service within an app.

It contains a WEB UI to visualize App properties and the service configuration read from the environment.
The UI also allows you to add new Redis key/value pairs and visualize all existing key/value pairs

Additionally you can also set, get and delete Redis key/value pairs using RESTful endpoints.

### Getting Started

Install the app by pushing it to your Cloud Foundry and binding with the Pivotal Redis service

Example:

     $ git clone git@github.com:pivotal-cf/cf-redis-example-app.git
     $ cd redis-example-app
     $ cf push redis-example-app --no-start
     $ cf create-service p-redis dedicated-vm redis-instance
     $ cf bind-service redis-example-app redis-instance
     $ cf start redis-example-app


### Datastore Endpoints

To access the Redis datastore CRUD actions directly and not through the UI views

#### PUT /store/:key

Sets the value stored in Redis at the specified key to a value posted in the 'data' field. Example:

    $ export APP=redis-example-app.my-cloud-foundry.com
    $ curl -X PUT $APP/store/foo -d 'data=bar'
    success


#### GET /store/:key

Returns the value stored in Redis at the key specified by the path. Example:

    $ curl -X GET $APP/store/foo
    bar

#### DELETE /store/:key

Deletes a Redis key spcified by the path. Example:

    $ curl -X DELETE $APP/store/foo
    success

# Cantaloup
set and get configuration

## Set
set value of the key

````
POST /api/kv/some/key?data=value
or
ALL /api/kv/some/key?method=POST&data=value
````
## Get
get value of the key

````
GET /api/kv/some/key
or
ALL /api/kv/some/key?method=GET
````
## Update
update value

````
PUT /api/kv/some/key?data=newvalue
or
ALL /api/kv/some/key?method=PUT&data=newvalue
````
## Delete
Remove key/value

````
DELETE /api/kv/some/key
or
ALL /api/kv/some/key?method=DELETE
````
## Link
Link one key to another

````
POST/PUT /api/kv/some/anotherKey?link=true&souce=/some/key
or
ALL /api/kv/some/anotherKey?method=(POST|PUT)&link=true&souce=/some/key
````
## Head
check value existence

````
HEAD /api/kv/some/key
or
ALL /api/kv/some/key?method=HEAD
````
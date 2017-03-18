# some kind of authenticatin or a secret here
import json
import urllib2

get_url = 'https://hackvalley-5be01.firebaseio.com/inventories/{id}/item_count.json'

item_id = 7

req = urllib2.Request(get_url.format(id=item_id))
req.add_header('type', 'GET')

response = urllib2.urlopen(req)
print response

"""
url = 'https://hackvalley-5be01.firebaseio.com/inventories/{id}/item_count'

postdata = {
	'item_count': str()
}

req = urllib2.Request(url)
req.add_header('Content-Type', 'application/json')
req.add_header('type', 'PUT')
data = json.dumps(postdata)

response = urllib2.urlopen(req, data)
"""

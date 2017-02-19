import grequests
from time import sleep

def createPoint(x, y):
    r = grequests.post('http://api.sconce.dev/jobs/1/points.json', data={'x': x, 'y': y})
    grequests.send(r, grequests.Pool(10))

createPoint(1, 2)
createPoint(2, 3)
createPoint(3, 2)
createPoint(4, 1)
sleep(0.1)

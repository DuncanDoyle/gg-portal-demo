#!/bin/sh

# BRANCH="feat/gp-2.4.0.rc5"
BRANCH="main"

TOKEN=eyJ0eXAiOiJ2bmQuYmFja3N0YWdlLnVzZXIiLCJhbGciOiJFUzI1NiIsImtpZCI6IjcxMjYwMTgzLTU3YzgtNDhiYy1iYmNmLWVkY2UzNDAxOWY1MyJ9.eyJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjcwMDcvYXBpL2F1dGgiLCJzdWIiOiJ1c2VyOmRldmVsb3BtZW50L2d1ZXN0IiwiZW50IjpbInVzZXI6ZGV2ZWxvcG1lbnQvZ3Vlc3QiXSwiYXVkIjoiYmFja3N0YWdlIiwiaWF0IjoxNzQzMTYwMzA2LCJleHAiOjE3NDMxNjM5MDYsInVpcCI6Il9kWVFXbVFQSGFQS2k2S1puQ2JwNjltNFl2bENKa2Fyd0EwZ2NKek1WSnhwbURJLTRDUmdXYTM0NzEyanA5aG5JcVVDQnZra0ZNczEyZW1QYXB2M2pBIn0.OfdGdJ01kzizW0KGyENAy891hpEZkPNfJRfQ2iS1pjHCmUhYV-hkCNULwtojUTT_an-jYLVba0oEZSn3Ldo3ug

curl -v -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "{\"target\":\"https://github.com/DuncanDoyle/gg-portal-demo/blob/$BRANCH/backstage/tracks-1.0-catalog-info.yaml\", \"type\":\"url\"}" \
    http://localhost:7007/api/catalog/locations

# curl -v -X POST -H "Content-Type: application/json" -H "Accept: application/json" \
#     -d "{\"target\":\"https://github.com/kcbabo/gg-portal-demo/blob/$BRANCH/backstage-catalog-entities/tracks-1.1-catalog-info.yaml\", \"type\":\"url\"}" \
#     http://localhost:7007/api/catalog/locations

# curl -v -X POST -H "Content-Type: application/json" -H "Accept: application/json" \
#     -d "{\"target\":\"https://github.com/kcbabo/gg-portal-demo/blob/$BRANCH/backstage-catalog-entities/petstore-catalog-info.yaml\", \"type\":\"url\"}" \
#     http://localhost:7007/api/catalog/locations
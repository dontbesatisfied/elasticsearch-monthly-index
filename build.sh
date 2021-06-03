# 0. 엘라스틱서치 실행 7.9.3 기준
docker-compose -f ./docker-compose.yml up -d

# curl: (52) Empty reply from server 에러가 발생하면 딜레이를 더 늘리면 된다.
sleep 30

# 1. 템플릿 생성
# https://www.elastic.co/guide/en/elasticsearch/reference/7.x/index-templates.html
# https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-aliases.html
curl -X PUT -H "Content-Type: application/json; charset=utf-8" -d '{
  "template": "mydata_*",
  "settings":{
    "index":{
      "number_of_shards":1,
      "number_of_replicas":0
    }
  },
  "mappings":{
      "dynamic":false,
      "properties":{
        "uploadedAt":{
            "type":"date"
        }
      }
  },
  "aliases": {
    "mydata": {}
  }
}' http://localhost:9210/_template/templates_test
# /_cat/templates 로 확인가능

# 2. 파이프라인 등록 (월별) 
# https://www.elastic.co/guide/en/elasticsearch/reference/7.x/date-index-name-processor.html
curl -X PUT -H "Content-Type: application/json; charset=utf-8" -d '{
   "description":"monthly date-time index naming",
   "processors":[
      {
         "date_index_name":{
            "field":"uploadedAt",
            "index_name_prefix":"mydata_",
            "date_rounding":"M",
            "index_name_format": "yyyy-MM",
            "timezone": "+09:00"
         }
      }
   ]
}' http://localhost:9210/_ingest/pipeline/mydata-monthly-index

# /_ingest/pipeline?pretty 로 확인가능

# 3. 데이터 삽입
curl -X PUT -H "Content-Type: application/json; charset=utf-8" -d '{
  "uploadedAt" : "2021-06-01T12:02:01.789Z"
}' http://localhost:9210/mydata/_doc/1?pipeline=mydata-monthly-index
# 응답
# {"_index":"mydata-2021-06","_type":"_doc","_id":"1","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":0,"_primary_term":1}

curl -X PUT -H "Content-Type: application/json; charset=utf-8" -d '{
  "uploadedAt" : "2021-05-10T12:02:01.789Z"
}' http://localhost:9210/mydata/_doc/2?pipeline=mydata-monthly-index
# 응답
# {"_index":"mydata-2021-05","_type":"_doc","_id":"2","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":2,"_primary_term":1}

# /_cat/indices, /_cat/aliases 로 확인가능

# 4. 쿼리 확인
curl -X GET -H "Content-Type: application/json; charset=utf-8" -d '{
  "query":{
    "match_all":{}
  }
}' http://localhost:9210/mydata/_search
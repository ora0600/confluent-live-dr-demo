export aEnv=$source_envid
export bEnv=$destination_envid
export aID=$cluster_source_id
export bID=$cluster_destination_id
export aBootstrap=$source_bootstrap
export bBootstrap=$destination_bootstrap
export topicname=cmtopic

export aApiKey="LDCAAEJF3KTN2HEC"
export aApiSecret="s/KVswBC5MFr2lWeiyxuX3aI2CkyvhKDShojcnj+hVPdlZ12lJU2Ewyv/2H9ywfY"
export bApiKey="NEOIU3SCOW2HB6UT"
export bApiSecret="39MPJiEVyCJxROKE+z2VOwhicQhWGapCiEfLMZYMhmzAxfTV28m1oPO6NTBre84D"
export saID=sa-oj33xo
confluent kafka topic create $topicname --cluster $aID --environment $aEnv
confluent kafka acl create --allow --service-account $saID --operations read,describe-configs --topic $topicname --cluster $aID --environment $aEnv
confluent kafka acl create --allow --service-account $saID --operations describe,alter --cluster-scope --cluster $aID --environment $aEnv
confluent kafka acl create --allow --service-account $saID --operations read,describe-configs --topic $topicname --cluster $bID --environment $bEnv
confluent kafka acl create --allow --service-account $saID --operations describe, alter --cluster-scope --cluster $bID --environment $bEnv
echo "link.mode=BIDIRECTIONAL">bidirectional-link.config
confluent kafka link create bidirectional-link \
--cluster $bID \
--environment $bEnv \
--source-bootstrap-server $bBootstrap \
--local-api-key $bApiKey \
--local-api-secret $bApiSecret \
--remote-cluster $aID \
--remote-api-key $aApiKey \
--remote-api-secret $aApiSecret \
--remote-bootstrap-server $aBootstrap \
--config bidirectional-link.config

confluent kafka link create bidirectional-link \
--cluster $aID \
--environment $aEnv \
--source-bootstrap-server $aBootstrap \
--local-api-key $aApiKey \
--local-api-secret $aApiSecret \
--remote-cluster $bID \
--remote-api-key $bApiKey \
--remote-api-secret $bApiSecret \
--remote-bootstrap-server $bBootstrap \
--config bidirectional-link.config

confluent kafka topic list --cluster $aID --environment $aEnv 
confluent kafka mirror create $topicname --link bidirectional-link --cluster $bID --environment $bEnv
confluent kafka mirror describe $topicname  --link bidirectional-link --cluster $bID --environment $bEnv
confluent kafka mirror reverse-and-start $topicname  --link bidirectional-link --cluster $bID --environment $bEnv
confluent kafka mirror describe $topicname  --link bidirectional-link --cluster $aID --environment $aEnv
confluent kafka mirror describe $topicname  --link bidirectional-link --cluster $bID --environment $bEnv
confluent kafka link task list bidirectional-link --cluster $aID --environment $aEnv
confluent kafka mirror reverse-and-pause $topicname --link bidirectional-link --cluster $aID --environment $aEnv
confluent kafka mirror describe $topicname  --link bidirectional-link --cluster $bID --environment $bEnv
confluent kafka mirror describe $topicname  --link bidirectional-link --cluster $aID --environment $aEnv
confluent kafka mirror resume $topicname   --link bidirectional-link --cluster $bID --environment $bEnv
confluent kafka mirror describe $topicname  --link bidirectional-link --cluster $bID --environment $bEnv
confluent kafka mirror describe $topicname  --link bidirectional-link --cluster $aID --environment $aEnv

import ballerina/log;
import ballerinax/aws.s3;

configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;
configurable string region = ?;

s3:ClientConfiguration amazonS3Config = {
    accessKeyId: accessKeyId,
    secretAccessKey: secretAccessKey,
    region: region
};

s3:Client amazonS3Client = check new (amazonS3Config);

public function main() {
    var listBucketResponse = amazonS3Client->listBuckets();
    if (listBucketResponse is s3:Bucket[]) {
        log:printInfo("Listing all buckets: ");
        foreach var bucket in listBucketResponse {
            log:printInfo("Bucket Name: " + bucket.name);
        }
    } else {
        log:printError("Error: " + listBucketResponse.toString());
    }
}

## Overview

The module provides the capability to manage buckets and objects in AWS S3.

This module supports [Amazon S3 REST API](https://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html) `2006-03-01` version.
 
## Configuring connector
### Prerequisites
- AWS account

### Obtaining tokens
 1. Create an Amazon account by visiting <https://aws.amazon.com/s3/>
 2. Create a new access key, which includes a new secret access key.
    - To create a new secret access key for your root account, use the [security credentials](https://console.aws.amazon.com/iam/home?#security_credential) page. Expand the Access Keys section, and then click **Create New Root Key**.
    - To create a new secret access key for an IAM user, open the [IAM console](https://console.aws.amazon.com/iam/home?region=us-east-1#home). Click **Users** in the **Details** pane, click the appropriate IAM user, and then click **Create Access Key** on the **Security Credentials** tab.
3. Download the newly created credentials, when prompted to do so in the key creation wizard.

**Note**
By default, the bucket is created in the US East (N. Virginia) Region. You can optionally specify a Region in the configuration. You might choose a Region to optimize latency, minimize costs, or address regulatory requirements.

## Quickstart

### Create a bucket
#### Step 1: Import the AWS S3 module
First, import the `ballerinax/aws.s3` module into the Ballerina project.
```ballerina
import ballerinax/aws.s3;
```

#### Step 2: Initialize the Calendar Client giving necessary credentials
Enter the credentials in the S3 client config.
```ballerina
s3:ClientConfiguration amazonS3Config = {
    accessKeyId: <ACCESS_KEY_ID>,
    secretAccessKey: <SECRET_ACCESS_KEY>,
    region: <REGION>
};

s3:Client amazonS3Client = check new (amazonS3Config);
```

#### Step 3: Call create bucket function
The `createBucket` remote function creates a bucket. The `bucketName` represents the name of the bucket that has to be created. This operation returns an `error` if unsuccessful. 

```ballerina
string bucketName = "name";

error? createBucketResponse = amazonS3Client->createBucket(bucketName);
if (createBucketResponse is error) {
    // If unsuccessful
    log:printError("Error: " + createBucketResponse.toString());
} else {
    // If successful
    log:printInfo("Bucket Creation Status: Success");
}
```

## Snippets

- List all buckets 

```ballerina
Bucket[]|error response =  amazonS3Client->listBuckets();
```

- List all buckets 

```ballerina
error? response = amazonS3Client->createObject(testBucketName, "test.txt", "Sample content");
```

### [You can find more samples here](https://github.com/ballerina-platform/module-ballerinax-aws.s3/tree/master/samples)
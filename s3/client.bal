// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

import ballerina/http;
import ballerina/regex;

# Amazon S3 connector client.
#
# + amazonS3 - HTTP client
@display {label: "Amazon S3", iconPath: "logo.png"}
public client class Client {
    private string accessKeyId;
    private string secretAccessKey;
    private string region;
    private string amazonHost = EMPTY_STRING;
    public http:Client amazonS3;
    private http:ClientConfiguration clientConfig = {http1Settings: {chunking: http:CHUNKING_NEVER}};

    # Initializes the AWS S3 connector client.
    # 
    # + amazonS3Config - Configuration required to initialize the `Client`
    # + return - An error on failure of initialization or else `()`
    public isolated function init(ClientConfiguration amazonS3Config) returns error? {
        self.region = (amazonS3Config?.region is string) ? <string>(amazonS3Config?.region) : DEFAULT_REGION;
        self.amazonHost = self.region != DEFAULT_REGION ? regex:replaceFirst(AMAZON_AWS_HOST, SERVICE_NAME,
            SERVICE_NAME + "." + self.region) :  AMAZON_AWS_HOST;
        string baseURL = HTTPS + self.amazonHost;
        self.accessKeyId = amazonS3Config.accessKeyId;
        self.secretAccessKey = amazonS3Config.secretAccessKey;
        check verifyCredentials(self.accessKeyId, self.secretAccessKey);  
        http:ClientSecureSocket? clientSecureSocket = amazonS3Config?.secureSocketConfig;
        if (clientSecureSocket is http:ClientSecureSocket) {
            self.clientConfig.secureSocket = clientSecureSocket;
        }
        self.amazonS3  = check new(baseURL, self.clientConfig);      
    }

    # Retrieves a list of all Amazon S3 buckets that the authenticated user of the request owns.
    # 
    # + return - If success, a list of Bucket record, else an error
    @display {label: "List Buckets"}
    remote function listBuckets() returns @tainted Bucket[]|error {
        map<string> requestHeaders = setDefaultHeaders(self.amazonHost);
        check generateSignature(self.accessKeyId, self.secretAccessKey, self.region, GET, SLASH, UNSIGNED_PAYLOAD,
            requestHeaders);
        http:Response httpResponse = check self.amazonS3->get(SLASH, requestHeaders);
        xml xmlPayload = check httpResponse.getXmlPayload();
        if (httpResponse.statusCode == http:STATUS_OK) {
            return getBucketsList(xmlPayload);
        }
        return error(xmlPayload.toString());
    }

    # Creates a bucket.
    # 
    # + bucketName - A unique name for the bucket
    # + cannedACL - The access control list of the new bucket
    # + return - An error on failure or else `()`
    @display {label: "Create Bucket"}
    remote function createBucket(@display {label: "Bucket Name"} string bucketName,
                                    @display {label: "Access Control List"} CannedACL? cannedACL = ()) returns 
                                    @tainted error? {
        http:Request request = new;
        string requestURI = string `/${bucketName}/`;
        map<string> requestHeaders = setDefaultHeaders(self.amazonHost);
        if (cannedACL != ()) {
            requestHeaders[X_AMZ_ACL] = cannedACL.toString();
        }
        if(self.region != DEFAULT_REGION) {
            xml xmlPayload = xml `<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> 
                                        <LocationConstraint>${self.region}</LocationConstraint> 
                                </CreateBucketConfiguration>`;   
            request.setXmlPayload(xmlPayload);
        }
        
        check generateSignature(self.accessKeyId, self.secretAccessKey, self.region, PUT, requestURI, UNSIGNED_PAYLOAD,
            requestHeaders, request);
        http:Response httpResponse = check self.amazonS3->put(requestURI, request);
        return handleHttpResponse(httpResponse);
    }

    # Retrieves the existing objects in a given bucket.
    # 
    # + bucketName - The name of the bucket
    # + delimiter - A delimiter is a character you use to group keys
    # + encodingType - The encoding method to be applied on the response
    # + maxKeys - The maximum number of keys to include in the response
    # + prefix - The prefix of the objects to be listed. If unspecified, all objects are listed
    # + startAfter - Object key from where to begin listing
    # + fetchOwner - Set to true, to retrieve the owner information in the response. By default the API does not return
    #                the Owner information in the response
    # + continuationToken - When the response to this API call is truncated (that is, the IsTruncated response element 
    #                       value is true), the response also includes the NextContinuationToken element. 
    #                       To list the next set of objects, you can use the NextContinuationToken element in the next 
    #                       request as the continuation-token
    # + return - If success, list of S3 objects, else an error
    @display {label: "List Objects"}
    remote function listObjects(@display {label: "Bucket Name"} string bucketName,
                                @display {label: "Group Identifier"} string? delimiter = (),
                                @display {label: "Encoding Type"} string?  encodingType = (),
                                @display {label: "Maximum Number of Keys"} int? maxKeys = (),
                                @display {label: "Required Object Prefix"} string? prefix = (),
                                @display {label: "Object Key Starts From"} string? startAfter = (),
                                @display {label: "Is Owner Information Required?"} boolean? fetchOwner = (),
                                @display {label: "Next List Token"} string? continuationToken = ()) returns @tainted
                                @display {label: "List of Objects"} S3Object[]|error {
        map<string> queryParamsMap = {};
        string requestURI = string `/${bucketName}/`;
        string queryParamsStr = "?list-type=2";
        queryParamsMap["list-type"] = "2";
        string queryParams = populateOptionalParameters(queryParamsMap, delimiter = delimiter, encodingType = 
            encodingType, maxKeys = maxKeys, prefix = prefix, startAfter = startAfter, fetchOwner = fetchOwner,
            continuationToken = continuationToken);
        queryParamsStr = string `${queryParamsStr}${queryParams}`;
        map<string> requestHeaders = setDefaultHeaders(self.amazonHost);

        check generateSignature(self.accessKeyId, self.secretAccessKey, self.region, GET, requestURI, UNSIGNED_PAYLOAD,
            requestHeaders, queryParams = queryParamsMap);
        requestURI = string `${requestURI}${queryParamsStr}`;
        http:Response httpResponse = check self.amazonS3->get(requestURI, requestHeaders);
        xml xmlPayload = check httpResponse.getXmlPayload();
        if (httpResponse.statusCode == http:STATUS_OK) {
            return getS3ObjectsList(xmlPayload);
        }
        return error(xmlPayload.toString());
    }

    # Retrieves objects from Amazon S3.
    #
    # + bucketName - The name of the bucket
    # + objectName - The name of the object
    # + objectRetrievalHeaders - Optional headers for the get object
    # + return - If success, S3ObjectContent object, else an error
    @display {label: "Get Object"}
    remote function getObject(@display {label: "Bucket Name"} string bucketName,
                                @display {label: "Object Name"} string objectName,
                                @display {label: "Object Retrieval Headers "} ObjectRetrievalHeaders?
                                objectRetrievalHeaders = ()) returns @tainted @display {label: "Object"} S3Object|error
                                {
        string requestURI = string `/${bucketName}/${objectName}`;
        map<string> requestHeaders = setDefaultHeaders(self.amazonHost);

        // Add optional headers.
        populateGetObjectHeaders(requestHeaders, objectRetrievalHeaders);
        
        check generateSignature(self.accessKeyId, self.secretAccessKey, self.region, GET, requestURI, UNSIGNED_PAYLOAD,
            requestHeaders);
        http:Response httpResponse = check self.amazonS3->get(requestURI, requestHeaders);
        if (httpResponse.statusCode == http:STATUS_OK) {
            byte[]|error binaryPayload = httpResponse.getBinaryPayload();
            if (binaryPayload is error) {
                return error(BINARY_CONTENT_EXTRACTION_ERROR_MSG, binaryPayload);
            } else {
                return getS3Object(binaryPayload);
            }
        } else {
            xml xmlPayload = check httpResponse.getXmlPayload();
            return error(xmlPayload.toString());
        }
    }

    # Creates an object.
    #
    # + bucketName - The name of the bucket
    # + objectName - The name of the object
    # + payload - The file content that needed to be added to the bucket
    # + cannedACL - The access control list of the new object
    # + objectCreationHeaders - Optional headers for the create object function
    # + return - An error on failure or else `()`
    @display {label: "Create Object"}
    remote function createObject(@display {label: "Bucket Name"} string bucketName,
                                    @display {label: "Object Name"} string objectName,
                                    @display {label: "File Content"} string|xml|json|byte[] payload,
                                    @display {label: "Grant"} CannedACL? cannedACL = (),
                                    @display {label: "Object Creation Headers"} ObjectCreationHeaders?
                                    objectCreationHeaders = ()) returns @tainted error? {
        http:Request request = new;
        string requestURI = string `/${bucketName}/${objectName}`;
        map<string> requestHeaders = setDefaultHeaders(self.amazonHost);
        if (payload is byte[]) {
            request.setBinaryPayload(payload, contentType = "application/octet-stream");
        } else {
            request.setPayload(payload);
        }
        
        // Add optional headers.
        populateCreateObjectHeaders(requestHeaders, objectCreationHeaders);
        
        check generateSignature(self.accessKeyId, self.secretAccessKey, self.region, PUT, requestURI, UNSIGNED_PAYLOAD,
            requestHeaders, request);
        http:Response httpResponse = check self.amazonS3->put(requestURI, request);
        return handleHttpResponse(httpResponse);
    }

    # Deletes an object.
    # 
    # + bucketName - The name of the bucket
    # + objectName - The name of the object
    # + versionId - The specific version of the object to delete, if versioning is enabled
    # + return - An error on failure or else `()`
    @display {label: "Delete Object"}
    remote function deleteObject(@display {label: "Bucket Name"} string bucketName,
                                    @display {label: "Object Name"} string objectName,
                                    @display {label: "Object Version"} string? versionId = ())
                                    returns @tainted error? {
        map<string> queryParamsMap = {};
        http:Request request = new;
        string queryParamsStr = "";
        string requestURI = string `/${bucketName}/${objectName}`;

        // Append query parameter(versionId).
        if (versionId is string) {
            queryParamsStr = string `${queryParamsStr}?versionId=${versionId}`;
            queryParamsMap["versionId"] = versionId;
        }    
        map<string> requestHeaders = setDefaultHeaders(self.amazonHost);
        
        check generateSignature(self.accessKeyId, self.secretAccessKey, self.region, DELETE, requestURI,
            UNSIGNED_PAYLOAD, requestHeaders, request, queryParams = queryParamsMap);
        requestURI = string `${requestURI}${queryParamsStr}`;
        http:Response httpResponse = check self.amazonS3->delete(requestURI, request);
        return handleHttpResponse(httpResponse);
    }     

    # Delete a bucket.
    # 
    # + bucketName - The name of the bucket
    # + return - An error on failure or else `()`
    @display {label: "Delete Bucket"}
    remote function deleteBucket(@display {label: "Bucket Name"} string bucketName) returns @tainted error? {
        http:Request request = new;
        string requestURI = string `/${bucketName}`;
        map<string> requestHeaders = setDefaultHeaders(self.amazonHost);
        
        check generateSignature(self.accessKeyId, self.secretAccessKey, self.region, DELETE, requestURI,
            UNSIGNED_PAYLOAD, requestHeaders, request);
        http:Response httpResponse = check self.amazonS3->delete(requestURI, request);
        return handleHttpResponse(httpResponse);
    }
}

isolated function setDefaultHeaders(string amazonHost) returns map<string> {
    map<string> requestHeaders = {
        [HOST]: amazonHost,
        [X_AMZ_CONTENT_SHA256]: UNSIGNED_PAYLOAD
    };
    return requestHeaders;
}

# Verifies the existence of credentials.
#
# + accessKeyId - The access key is of the Amazon S3 account
# + secretAccessKey - The secret access key of the Amazon S3 account
# 
# + return - An error on failure or else `()`
isolated function verifyCredentials(string accessKeyId, string secretAccessKey) returns error? {
    if ((accessKeyId == "") || (secretAccessKey == "")) {
        return error(EMPTY_VALUES_FOR_CREDENTIALS_ERROR_MSG);
    }
}

# AmazonS3 Connector configurations.
# + accessKeyId - The access key is of the Amazon S3 account
# + secretAccessKey - The secret access key of the Amazon S3 account
# + region - The AWS Region. If you don't specify an AWS region, Client uses US East (N. Virginia) as 
#            default region
# + secureSocketConfig - Secure Socket config
@display {label: "Connection Config"}
public type ClientConfiguration record {
    @display {label: "Access Key ID"}
    string accessKeyId;
    @display {label: "Secret Access Key"}
    string secretAccessKey;
    @display {label: "Region"}
    string region?;
    @display {label: "SSL Config"}
    http:ClientSecureSocket secureSocketConfig?;
};

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

public const ACL_PRIVATE = "private";
public const ACL_PUBLIC_READ = "public-read";
public const ACL_PUBLIC_READ_WRITE = "public-read-write";
public const ACL_AUTHENTICATED_READ = "aws-exec-read";
public const ACL_LOG_DELIVERY_WRITE = "authenticated-read";
public const ACL_BUCKET_OWNER_READ = "bucket-owner-read";
public const ACL_BUCKET_OWNER_FULL_CONTROL = "bucket-owner-full-control";
public type CannedACL ACL_PRIVATE|ACL_PUBLIC_READ|ACL_PUBLIC_READ_WRITE|ACL_AUTHENTICATED_READ|ACL_LOG_DELIVERY_WRITE|
                    ACL_BUCKET_OWNER_READ|ACL_BUCKET_OWNER_FULL_CONTROL;

# Defines bucket.
# 
# + name - The name of the bucket
# + creationDate - The creation date of the bucket
public type Bucket record {
    string name;
    string creationDate;
};

# Define S3Object.
# 
# + objectName - The name of the object
# + lastModified - The last modified date of the object
# + eTag - The etag of the object
# + objectSize - The size of the object
# + ownerId - The id of the object owner
# + ownerDisplayName - The display name of the object owner
# + storageClass - The storage class of the object
# + content - The content of the object
public type S3Object record {
    string objectName?;
    string lastModified?;
    string eTag?;
    string objectSize?;
    string ownerId?;
    string ownerDisplayName?;
    string storageClass?;
    byte[] content?;
};

# Represents the optional headers specific to getObject function.
#
# + modifiedSince - Return the object only if it has been modified since the specified time
# + unModifiedSince - Return the object only if it has not been modified since the specified time
# + ifMatch - Return the object only if its entity tag (ETag) is the same as the one specified
# + ifNoneMatch - Return the object only if its entity tag (ETag) is different from the one specified
# + range - Downloads the specified range bytes of an object
public type ObjectRetrievalHeaders record {
    @display {label: "Modified Since"}
    string modifiedSince?;
    @display {label: "Unmodified Since"}
    string unModifiedSince?;
    @display {label: "If Match"}
    string ifMatch?;
    @display {label: "If None Match"}
    string ifNoneMatch?;
    @display {label: "Range"}
    string range?;
};

# Represents the optional headers specific to createObject function.
#
# + cacheControl - Can be used to specify caching behavior along the request/reply chain
# + contentDisposition - Specifies presentational information for the object.
# + contentEncoding - Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field
# + contentLength - The size of the object, in bytes
# + contentMD5 - The base64-encoded 128-bit MD5 digest of the message (without the headers)
# + expect - When your application uses 100-continue, it does not send the request body until it receives an acknowledgment.The date and time at which the object is no longer able to be cached
# + expires - The date and time at which the object is no longer cacheable
public type ObjectCreationHeaders record {
    @display {label: "Cache Control"}
    string cacheControl?;
    @display {label: "Content Disposition"}
    string contentDisposition?;
    @display {label: "Content Encoding"}
    string contentEncoding?;
    @display {label: "Content Length"}
    string contentLength?;
    @display {label: "MD5 of Content"}
    string contentMD5?;
    @display {label: "Expect"}
    string expect?;
    @display {label: "Expiry Time"}
    string expires?;
};

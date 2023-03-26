import os
import face_recognition
import pickle
import boto3
import csv

s3_client = boto3.client('s3')
output_bucket = "output-bucket-cc-project-2"
encoding_path = "/root/encoding"
dynamo_table = "student_data"

def face_recognition_handler(event, context):
    print("Entered face_recognition_handler")
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    downloads3(bucket, key)
    video_location = "/tmp/" + key
    image_path = extract_frame(video_location)
    face_name = recognition(image_path)
    csv_file_name = createCSV(key, face_name)
    uploads3(output_bucket, csv_file_name)
    delete_temp(image_path)

def downloads3(s3_bucket_name, video_name):
    # Download the video file to /tmp/
    print("Entered downloads3")
    file_name = "/tmp/" + video_name
    s3_client.download_file(s3_bucket_name, video_name, file_name)

def extract_frame(video_location):
    # Extract frames from video using ffmpeg in 1-second interval
    print("Entered extract_frame")
    video_name = video_location.rsplit(".",1)[0]
    file_name = video_name.rsplit("/")[2]
    file_name = file_name + ".jpeg"
    path = "/tmp/"
    os.system("ffmpeg -i " + str(video_location) + " -vframes 1 " + str(path) + file_name)
    image_path = "/tmp/" + file_name
    return image_path

def delete_temp(image_path):
    # Delete image files from /tmp/
    print("Entered delete_temp")
    if os.path.exists(image_path):
    	os.remove(image_path)

def recognition(image_path):
    # Execute face recognition on extracted frame images
    print("Entered recognition")
    image = face_recognition.load_image_file(image_path)
    image_encoding = face_recognition.face_encodings(image)[0]
    with open(encoding_path,'rb') as f:
        all_face_encodings = pickle.load(f)
        face_names = list(all_face_encodings.keys())
        face_encodings = list(all_face_encodings.values())
        face_names = face_encodings[0]
    face_encodings = all_face_encodings['encoding']
    result = face_recognition.compare_faces(face_encodings, image_encoding)
    for res in result:
        if res:
            idx = result.index(res)
            return(face_names[idx])

def query_db(name):
    # Query DynamoDB table to get row with given "name"
    print("Entered query_db")
    dynamodb_client = boto3.client('dynamodb')
    response = dynamodb_client.get_item(
        TableName = dynamo_table,
        Key={
            'name': {'S': name}
        }
    )
    print(response['Item'])
    return (response['Item'])


def createCSV(videoName, face_name):
    # Create CSV file using retrieved row from DynamoDB
    print("Entering CSV creation")
    video_name = videoName.rsplit(".",1)[0]
    file_name = "/tmp/" + video_name + ".csv"
    with open(file_name, 'a') as f:
        writer = csv.writer(f)
        student_data = query_db(face_name)
        name = student_data['name']['S']
        major = student_data['major']['S']
        year = student_data['year']['S']
        writer.writerow([name, major, year])
    return file_name


def uploads3(s3_bucket_name, csv_name):
    # Upload CSV file to S3 output bucket
    print("Entering S3 upload")
    object_name = csv_name.rsplit("/")[2]
    s3_client.upload_file(csv_name, s3_bucket_name, object_name)
    print("File uploaded")


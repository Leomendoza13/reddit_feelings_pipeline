from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType,
    StructField,
    StringType,
    TimestampType,
    IntegerType,
    ArrayType,
    FloatType,
)
from pyspark.sql.functions import from_unixtime, col, explode, current_timestamp, udf
from transformers import pipeline

spark = (
    SparkSession.builder.appName("feeling analysis")
    .config("spark.jars", "/opt/bitnami/spark/jars/gcs-connector-hadoop3-2.2.11.jar")
    .config("fs.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem")
    .config(
        "fs.AbstractFileSystem.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS"
    )
    .getOrCreate()
)


@udf(StringType(), useArrow=True)
def analyze_sentiment(text):

    sentiment_analyzer = pipeline(
        task="sentiment-analysis",
        model="distilbert-base-uncased-finetuned-sst-2-english",
        device=-1,
    )
    if not text:
        return "neutral"
    try:
        if len(text) > 512:
            print(f"Attention: Texte tronqué de {len(text)} à 512 caractères")
        result = sentiment_analyzer(text[:512])[0]
        if result["label"] == "POSITIVE":
            if result["score"] > 0.8:
                return "très positif"
            return "positif"
        elif result["label"] == "NEGATIVE":
            if result["score"] > 0.8:
                return "très négatif"
            return "négatif"
        return "neutre"
    except Exception as e:
        print(f"Erreur lors de l'analyse: {str(e)}")
        return "neutre"


schema = StructType(
    [
        StructField("title", StringType(), True),
        StructField("id", StringType(), True),
        StructField("url", StringType(), True),
        StructField("score", IntegerType(), True),
        StructField("author", StringType(), True),
        StructField("created_utc", FloatType(), True),
        StructField("num_comments", IntegerType(), True),
        StructField("selftext", StringType(), True),
        StructField("subreddit", StringType(), True),
        StructField(
            "comments",
            ArrayType(
                StructType(
                    [
                        StructField("id", StringType(), True),
                        StructField("author", StringType(), True),
                        StructField("body", StringType(), True),
                        StructField("score", IntegerType(), True),
                        StructField("created_utc", FloatType(), True),
                        StructField("parent_id", StringType(), True),
                        StructField("is_submitter", StringType(), True),
                    ]
                )
            ),
            True,
        ),
    ]
)

streaming_df = (
    spark.readStream.format("json")
    .schema(schema)
    .option("maxFilesPerTrigger", 1)
    .option("latestFirst", "true")
    .option("cleanSource", "archive")
    .load("gs://reddit-feelings-pipeline-bucket/*.json")
)

posts_df = streaming_df.select(
    "id",
    "title",
    "url",
    "score",
    "author",
    "num_comments",
    "selftext",
    "subreddit",
    from_unixtime("created_utc").alias("post_date"),
    current_timestamp().alias("processing_time"),
)


comments_df = (
    streaming_df.select("id", explode("comments").alias("comment"))
    .select(
        col("id").alias("post_id"),
        col("comment.id").alias("comment_id"),
        col("comment.author").alias("comment_author"),
        col("comment.body").alias("comment_body"),
        col("comment.score").alias("comment_score"),
        from_unixtime("comment.created_utc").alias("comment_date"),
        current_timestamp().alias("processing_time"),
    )
    .withColumn("sentiment", analyze_sentiment(col("comment_body")))
)

project_id = "reddit-feelings-pipeline"
dataset = "dataset"

posts_query = (
    posts_df.writeStream.format("bigquery")
    .option("table", f"{project_id}.{dataset}.posts")
    .option("checkpointLocation", "reddit-feelings-pipeline-process-bucket/posts")
    .option("failOnDataLoss", "false")
    .option("maxRetries", 3)
    .outputMode("append")
    .trigger(processingTime="1 minute")
    .start()
)

comments_query = (
    comments_df.writeStream.format("bigquery")
    .option("table", f"{project_id}.{dataset}.comments")
    .option("checkpointLocation", "reddit-feelings-pipeline-process-bucket/comments")
    .option("failOnDataLoss", "false")
    .option("maxRetries", 3)
    .outputMode("append")
    .trigger(processingTime="1 minute")
    .start()
)

try:
    spark.streams.awaitAnyTermination()
finally:
    posts_query.stop()
    comments_query.stop()
    spark.stop()

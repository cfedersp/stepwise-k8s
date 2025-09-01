from airflow.sdk import dag, task
import pendulum

@dag(
    schedule=None,
    start_date=pendulum.datetime(2021, 1, 1, tz="UTC"),
    catchup=False,
    tags=["example"],
)

def dagFactory():
  @task()
  def loadFile():
    print("Loading input file");
  
  @task()
  def transformFile():
    print("Transforming file");
  
  @task()
  def uploadFile():
    print("hello taskflow!")

  loadTask = loadFile();
  transformTask = transformFile();
  uploadTask = uploadFile();

  loadTask >> transformTask >> uploadTask
  # loadTask = loadFile();
  # transformTask = transformFile(loadTask);
  # uploadTask = uploadFile(transformTask);

dagFactory();

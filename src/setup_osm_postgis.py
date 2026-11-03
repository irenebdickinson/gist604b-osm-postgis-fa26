"""
OSM PostGIS Setup Workflow - Student Implementation
"""

import os
import psycopg2
import requests
import subprocess
import zipfile
from pathlib import Path
from typing import Optional


def setup_osm_postgis(
    osm_url: str,
    db_name: str = "osm_db",
    user: str = "postgres",
    password: str = "postgres",
    host: str = "localhost",
    port: int = 5432,
    data_dir: Optional[Path] = None,
    load_shapefiles: Optional[list[str]] = None
) -> None:
    """
    Create a PostGIS database and load Geofabrik shapefile data.

    Args:
        osm_url: URL to Geofabrik shapefile ZIP
        db_name: Name of the database to create
        user: PostgreSQL username
        password: PostgreSQL password
        host: Database host
        port: Database port
        data_dir: Optional directory to store downloaded OSM data
        load_shapefiles: Optional list of shapefile layer names to load

    Returns:
        None
    """

    # Step 1: Setup data directory
    if data_dir is None:
        data_dir = Path(f"../data/{db_name}")
    else:
        data_dir = Path(data_dir)
    data_dir.mkdir(parents=True, exist_ok=True)

    file_path = data_dir / osm_url.split("/")[-1]

    # Step 2: Download shapefile ZIP data
    if not file_path.exists():
        print("Downloading shapefile data...")
        print("URL:", osm_url)
        response = requests.get(osm_url, stream=True, timeout=300)
        response.raise_for_status()

        file_size = int(response.headers.get("content-length", 0))
        if file_size > 0:
            print(f"File size: {file_size / (1024 * 1024):.1f} MB")

        downloaded = 0
        with open(file_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if file_size > 0:
                        progress = downloaded / file_size * 100
                        print(f"\rProgress: {progress:.1f}%", end="", flush=True)
        print("\nDownload complete")
        print("Saved to:", file_path)
    else:
        print("File already exists:", file_path)

    # Step 3: Connect to PostgreSQL (default database)
    conn = psycopg2.connect(dbname="postgres", user=user, password=password,
                            host=host, port=port)
    conn.autocommit = True
    cur = conn.cursor()
    print("Connected to PostgreSQL server")

    # Step 4: Create the working database
    cur.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (db_name,))
    if not cur.fetchone():
        cur.execute(f'CREATE DATABASE "{db_name}";')
        print(f"Database '{db_name}' created")
    else:
        print(f"Database '{db_name}' already exists")

    cur.close()
    conn.close()
    print("Closed connection to 'postgres'")

    # Step 5: Connect to the new database
    conn = psycopg2.connect(dbname=db_name, user=user, password=password,
                            host=host, port=port)
    conn.autocommit = True
    cur = conn.cursor()
    print("Connected to database:", db_name)

    # Step 6: Enable PostGIS
    cur.execute("CREATE EXTENSION IF NOT EXISTS postgis;")
    cur.execute("SELECT PostGIS_version();")
    print("PostGIS version:", cur.fetchone()[0])

    # Step 7: Unzip shapefile data
    extract_path = data_dir / "shapefiles"
    if not extract_path.exists():
        print("Extracting shapefiles...")
        with zipfile.ZipFile(file_path, "r") as zip_ref:
            zip_ref.extractall(extract_path)
        print("Extracted to:", extract_path)
    else:
        print("Extracted folder already exists:", extract_path)

    # Step 8: Load shapefiles into PostGIS using shp2pgsql
    env = os.environ.copy()
    env["PGPASSWORD"] = password

    shp_files = [f for f in os.listdir(extract_path) if f.endswith(".shp")]
    for shp_file in shp_files:
        filename = os.path.splitext(shp_file)[0]
        table_name = filename.replace("gis_osm_", "").replace("_free_1", "")

        if load_shapefiles is not None and table_name not in load_shapefiles:
            continue

        shp_path = os.path.join(extract_path, shp_file)
        print(f"\nLoading {table_name} from {filename}...")
        cmd = (f'shp2pgsql -d -I -s 4326 "{shp_path}" public.{table_name} '
               f'| psql -h {host} -U {user} -d {db_name}')
        try:
            subprocess.run(cmd, shell=True, env=env, check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
            print(f"{table_name} loaded successfully")
        except subprocess.CalledProcessError as e:
            print(f"{table_name} failed")
            print(e.stderr.splitlines()[-1] if e.stderr else e)

    # Step 9: Close connections
    cur.close()
    conn.close()
    print("Database connection closed")
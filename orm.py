from sqlalchemy import create_engine, Column, Integer, String, Text, DECIMAL
from sqlalchemy.orm import declarative_base, sessionmaker

username = "root"
password = ""
host = "localhost"
port = "3306"
database = "smejkal_radek-f22156"


engine = create_engine(
    f"mysql+mysqlconnector://{username}:{password}@{host}:{port}/{database}"
)

Base = declarative_base()


class MonitorView(Base):
    __tablename__ = "monitor_view"
    id = Column(Integer, primary_key=True)
    monitor = Column(String(50))
    vyrobce = Column(String(50))
    popis_vyrobce = Column(String(500))
    uhlopricka = Column(String(23))
    typ_panelu = Column(String(20))
    rozliseni_nazev = Column(String(50), nullable=False)
    rozliseni_sirka = Column(String(23))
    rozliseni_vyska = Column(String(23))
    frekvence = Column(String(23))
    konektory_monitoru = Column(Text)
    funkce_monitoru = Column(Text)
    prumerne_hodnoceni = Column(DECIMAL(14, 4))
    pocet_recenzi = Column(Integer)


Base.metadata.create_all(engine)


Session = sessionmaker(bind=engine)
session = Session()

monitor_view_query = session.query(MonitorView)
monitor_view_results = monitor_view_query.all()

print("Monitory:")
for monitor_view in monitor_view_results:
    print(f"ID: {monitor_view.id}")
    print(f"Monitor ID: {monitor_view.monitor}")
    print(f"Výrobce: {monitor_view.vyrobce}")
    print(f"Popis Vyrobce: {monitor_view.popis_vyrobce}")
    print(f"Uhlopříčka: {monitor_view.uhlopricka}")
    print(f"Typ Panelu: {monitor_view.typ_panelu}")
    print(f"Rozlišeni Název: {monitor_view.rozliseni_nazev}")
    print(f"Rozlišeni Šířka: {monitor_view.rozliseni_sirka}")
    print(f"Rozlišení Výška: {monitor_view.rozliseni_vyska}")
    print(f"Frekvence: {monitor_view.frekvence}")
    print(f"Konektory Monitoru: {monitor_view.konektory_monitoru}")
    print(f"Funkce Monitoru: {monitor_view.funkce_monitoru}")
    print(f"Průměrné Hodnocení: {monitor_view.prumerne_hodnoceni}")
    print(f"Počet Recenzí: {monitor_view.pocet_recenzi}")
    print("--------------------------------------")

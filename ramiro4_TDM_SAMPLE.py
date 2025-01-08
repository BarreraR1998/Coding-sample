import pandas as pd
import numpy as np
import random
from tqdm import tqdm
tqdm.pandas
from timeMachine_felipe_v1 import TimeMachine
import math
import csv
import os
import matplotlib 
from matplotlib import pyplot as plt
import re
import threading
import time

tqdm.pandas

os.chdir(r'C:\Users\56966\Dropbox\BIDMapuche')

data_dir = os.path.join(os.getcwd(), 'data')


########################################################################

class TimeoutException(Exception):
    pass

def execute_with_timeout(timeout, func, *args, **kwargs):
    """
    Ejecuta una función con un límite de tiempo.
    Si la función no completa en el tiempo especificado, lanza TimeoutException.
    """
    result = [None]
    exception = [None]

    def wrapper():
        try:
            result[0] = func(*args, **kwargs)
        except Exception as e:
            exception[0] = e

    thread = threading.Thread(target=wrapper)
    thread.start()
    thread.join(timeout)
    if thread.is_alive():
        thread.join(0)  # Garantiza que el subproceso termine correctamente
        raise TimeoutException(f"Execution timed out after {timeout} seconds")
    

# PROCESO DE FILAS

def process_single_row(row, start_year, pivot, end_year, cancelapor2, directory):

    id_reg = row['id_reg']
    tm = TimeMachine([id_reg],min_year=1969)
    futuros = tm.forward()
    pasados = tm.backwards()

    return(futuros, pasados)


def plot_travelling(ids_reg, start_year, pivot, end_year, directory):

    # Inicializar el archivo CSV con las columnas
    with open(directory, 'w+', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['id_original', 'id_travel', 'year', 'share'])  # Define las columnas

    cancelapor2 = pd.read_csv(r'C:\Users\56966\Dropbox\BIDMapuche\data\processed\CBRT_ALL\canceladopor.csv')[['id_reg', 'id_reg_c']].rename(columns={'id_reg': 'id_travel'})
    cancelapor2 = cancelapor2.loc[~cancelapor2['id_travel'].isin(['00000000000000F', '18990000100001F'])]
    cancelapor2 = cancelapor2.sort_values(by=['id_travel', 'id_reg_c']).drop_duplicates(subset='id_travel', keep='last')
    cancelapor2['last_por'] = cancelapor2['id_reg_c'].str[:4].astype(float)

    
    # Iterar sobre cada registro
    for _, row in tqdm(ids_reg.iterrows(), total=ids_reg.shape[0], desc="Procesando registros"):
        try:
            execute_with_timeout(10, process_single_row, row, start_year, pivot, end_year, cancelapor2, directory)
            
            id_reg = row['id_reg']
            all_rows = []
            rows = []

            for fut in futuros:  # MAPEO WIDE
                transition_dict = {int(id[:4]): id for id in fut}
                current_id = id_reg
                row_values = [id_reg]

                for year in range(pivot, end_year + 1):
                    if year in transition_dict:
                        current_id = transition_dict[year]
                    row_values.append(current_id)
                    rows.append([id_reg, current_id, year])
                            
                all_rows.append(row_values)
                    
            long_df = pd.DataFrame(rows, columns=['id_original', 'id_travel', 'year']);
                            
            column_names = ['id_original'] + [f'y{year}' for year in range(pivot, end_year + 1)]
            wide_df = pd.DataFrame(all_rows, columns=column_names);

                # ELIMINAR SIAMESES
            for agno in range(1994, 2024):
                wide_df = wide_df.merge(cancelapor2[['id_travel', 'last_por']], how='left',
                                                left_on=f'y{agno}', right_on='id_travel')
                wide_df['last_por'] = wide_df['last_por'].fillna(2025)
                wide_df = wide_df.loc[~(wide_df['last_por'] < agno)]
                wide_df = wide_df.drop(columns=['last_por', 'id_travel'])

                # CALCULAR SHARES
            D = []
            WS = []
            for i,y in enumerate(wide_df.columns[1:]):
                shares = 1/wide_df[wide_df.columns[:i+2].to_list()].groupby(wide_df.columns[:i+1].to_list()).nunique() #Share

                shares = 1 / wide_df[wide_df.columns[:i+2].to_list()].groupby(wide_df.columns[:i+1].to_list()).nunique()
                shares = shares.reset_index().sort_values(by=wide_df.columns[:i+1].to_list())  # Asegurar el orden correcto
                shares = shares.set_index(wide_df.columns[:i+1].to_list())

                        
                hist = wide_df.copy()
                hist['h'] = wide_df[wide_df.columns[:i+1]].apply(lambda y: '-'.join([str(x)for x in y]),axis=1)       
                hist = hist[[wide_df.columns[i+1],'h']]

                aux = hist.groupby(wide_df.columns[i+1]).count()/ hist.groupby(wide_df.columns[i+1]).nunique()
                aux = aux.reset_index().sort_values(by=wide_df.columns[i+1])  # Asegurar el orden correcto
                aux = aux.set_index(wide_df.columns[i+1])

                dc = wide_df.copy()
                dc = dc.merge(shares,left_on=wide_df.columns[:i+1].to_list(),right_index=True,how='left')
                        
                W = wide_df.copy()
                W= W.merge(aux,left_on=y,right_index=True)
                D.append(dc[str(y)+'_y'].to_list())
                WS.append(W['h'].to_list())


            PI = pd.DataFrame(np.array(D).T.cumprod(axis=1));
            O = PI/np.array(WS).T
            O.columns = [f"share{1992 + i+ 1}" for i in range(0, PI.shape[1])]

            wide_df = wide_df.merge(O, how='left', left_index=True, right_index=True);

            # MERGE SHARES WITH LONG
            aux = wide_df[['y1993', 'share1993']].groupby('y1993')['share1993'].sum().reset_index()
            aux = aux.rename(columns={'y1993': 'id_travel'})
            aux['year'] = 1993
            long_df = long_df.merge(aux[['id_travel', 'year', 'share1993']], how='left', on=['year', 'id_travel'])

            long_df['share'] = np.where(long_df['year'] == 1993, long_df['share1993'], np.nan)
            long_df = long_df.drop(columns=['share1993'])

            for i in range(0, 31):
                year = 1993 + i
                aux = wide_df[[f'y{year}', f'share{year}']].groupby(f'y{year}')[f'share{year}'].sum().reset_index()
                aux['year'] = year
                aux = aux.rename(columns={f'y{year}': 'id_travel'})
                long_df = long_df.merge(aux[['id_travel', 'year', f'share{year}']], how='left', on=['year', 'id_travel'])

                long_df['share'] = np.where(long_df['year'] == year,
                                                    long_df[f'share{year}'],
                                                    long_df['share'])
                long_df = long_df.drop(columns=[f'share{year}'])
                    ###############################################
                    # PAST-TRACKING
            rows = []
            all_rows = []
            rows = []

            for pas in pasados:
                    # Crear el diccionario de transiciones
                transition_dict = {int(id[:4]): id for id in pas}
                first_transition_year = min(transition_dict.keys())  # Año más antiguo en las transiciones
                oldest_id = transition_dict[first_transition_year]  # ID más antiguo del historial
                current_id = oldest_id

                    # Crear una lista para esta fila (formato wide)
                row_values = [id_reg]  # Comienza con el ID original

                for year in range(start_year, pivot + 1):
                    if year in transition_dict:
                                # Si el año está en las transiciones, actualiza `current_id`
                        current_id = transition_dict[year]
                    elif year < first_transition_year:
                            # Si el año es anterior al inicio conocido, usa el valor más antiguo
                        current_id = oldest_id
                    rows.append([id_reg, current_id, year])
                            # Agregar el ID actual al valor de la fila
                    row_values.append(current_id)

                        # Agregar la fila completa a all_rows
                all_rows.append(row_values)

                    # Crear el DataFrame en formato long y wide
            long_df2 = pd.DataFrame(rows, columns=['id_original', 'id_travel', 'year']);
            column_names = ['id_original'] + [f'y{year}' for year in range(start_year, pivot + 1)]
            wide_df = pd.DataFrame(all_rows, columns=column_names);
            wide_df = wide_df.iloc[:, ::-1]
            cols = ['id_original'] + [col for col in wide_df.columns if col != 'id_original']
            wide_df = wide_df[cols]

            D = []
            WS = []
            for i,y in enumerate(wide_df.columns[1:]):
                shares = 1/wide_df[wide_df.columns[:i+2].to_list()].groupby(wide_df.columns[:i+1].to_list()).nunique() #Share

                shares = 1 / wide_df[wide_df.columns[:i+2].to_list()].groupby(wide_df.columns[:i+1].to_list()).nunique()
                shares = shares.reset_index().sort_values(by=wide_df.columns[:i+1].to_list())  # Asegurar el orden correcto
                shares = shares.set_index(wide_df.columns[:i+1].to_list())

                hist = wide_df.copy()
                hist['h'] = wide_df[wide_df.columns[:i+1]].apply(lambda y: '-'.join([str(x)for x in y]),axis=1)       
                hist = hist[[wide_df.columns[i+1],'h']]

                aux = hist.groupby(wide_df.columns[i+1]).count()/ hist.groupby(wide_df.columns[i+1]).nunique()
                aux = aux.reset_index().sort_values(by=wide_df.columns[i+1])  # Asegurar el orden correcto
                aux = aux.set_index(wide_df.columns[i+1])

                dc = wide_df.copy()
                dc = dc.merge(shares,left_on=wide_df.columns[:i+1].to_list(),right_index=True,how='left')
                                
                W = wide_df.copy()
                W= W.merge(aux,left_on=y,right_index=True)
                D.append(dc[str(y)+'_y'].to_list())
                WS.append(W['h'].to_list())


            PI = pd.DataFrame(np.array(D).T.cumprod(axis=1));
            O = PI/np.array(WS).T
            O.columns = [f"share{pivot - i }" for i in range(0, PI.shape[1])]

            wide_df = wide_df.merge(O, how='left', left_index=True, right_index=True);

                # MERGE SHARES WITH LONG
            aux = wide_df[[f'y{start_year}', f'share{start_year}']].groupby(f'y{start_year}')[f'share{start_year}'].sum().reset_index()
            aux = aux.rename(columns={f'y{start_year}': 'id_travel'})
            aux['year'] = start_year
            long_df2 = long_df2.merge(aux[['id_travel', 'year', f'share{start_year}']], how='left', on=['year', 'id_travel'])

            long_df2['share'] = np.where(long_df2['year'] == start_year, long_df2[f'share{start_year}'], np.nan)
            long_df2 = long_df2.drop(columns=[f'share{start_year}'])

            for i in range(start_year + 1, pivot+1):
                year = i
                aux = wide_df[[f'y{i}', f'share{i}']].groupby(f'y{i}')[f'share{i}'].sum().reset_index()
                aux['year'] = i
                aux = aux.rename(columns={f'y{i}': 'id_travel'})
                long_df2 = long_df2.merge(aux[['id_travel', 'year', f'share{i}']], how='left', on=['year', 'id_travel'])

                long_df2['share'] = np.where(long_df2['year'] == i,
                                                        long_df2[f'share{i}'],
                                                            long_df2['share'])
                long_df2 = long_df2.drop(columns=[f'share{i}'])
            long_df3 = pd.concat([long_df,long_df2 ]).drop_duplicates(subset=['id_original','id_travel','year'])
            # ESCRIBIR LONG_DF EN CSV
            with open(directory, 'a', newline='') as file:
                writer = csv.writer(file)
                for _, filas in long_df3.iterrows():
                    writer.writerow(filas)

        except TimeoutException:
            print(f"Se agotó el tiempo para el registro: {row['id_reg']}")      
    

directory = os.path.join('data', 'processed', 'SAMPLE', 'SAMPLE_TMD', 'tdmSample_notmatched.csv')
pre_match = pd.read_csv(directory)


start_year= 1979
end_year = 2023
pivot= 1993

initial = os.path.join('data', 'processed', 'SAMPLE', 'SAMPLE_TMD', 'tdmSample_notmatched.csv')
directory = os.path.join('data', 'processed', 'SAMPLE', 'SAMPLE_TMD', 'TDM_post_match.csv')
directory_aux = os.path.join('data', 'processed', 'SAMPLE', 'SAMPLE_TMD', 'auxi.csv')

df = pd.read_csv(initial).drop_duplicates(subset=['id_reg'])[['id_reg']]
MATCH = pd.read_csv(directory).drop_duplicates(subset=['id_original'], keep='first')[['id_original']].rename(columns={'id_original':'id_reg'})
NO_MATCH = df.merge(MATCH, how='left', on='id_reg', indicator='merge_')
NO_MATCH = NO_MATCH.loc[NO_MATCH['merge_']=='left_only'].drop_duplicates(subset='id_reg')[['id_reg']]

NO_MATCH = NO_MATCH.sort_values(by='id_reg', ascending=0)

del(df,MATCH)
plot_travelling(NO_MATCH, start_year, pivot , end_year, directory_aux)

auxi = pd.read_csv(directory_aux)

MATCH= pd.read_csv(directory)
MATCH = pd.concat([MATCH, auxi])
os.remove(directory_aux)
MATCH.to_csv(directory)

#!pip install playsound
from playsound import playsound
gol = r'C:\Users\56966\Dropbox\Personal\gol.mp3'
playsound(gol)
print('playing sound using  playsound')
## GOAL SOUND WHEN FUNCTION STOP RUNNING


#CUSTOMIZATION OF DF FOR REGRESION IN STATA 

replace = 1
directory = 'replace' if replace == 1 else 'noreplace'

temu = 1
directory_2 = 'temuco' if temu == 1 else 'all'

tercera_opcion = 0
directory_2 = 'pre79' if tercera_opcion == 1 else directory_2


df = pd.read_csv(rf'C:\Users\56966\Dropbox\BIDMapuche\data\processed\SAMPLE\SAMPLE_TMD\matched_data_{directory}_{directory_2}.csv'
                 ).rename(columns={'tdm2':"TDM2",'year':'Year'})


MATCH = pd.read_csv(r'C:\Users\56966\Dropbox\BIDMapuche\data\processed\SAMPLE\SAMPLE_TMD\TDM_post_match.csv'
                    ).drop_duplicates(subset=['id_original','id_travel','year'], keep='first').rename(columns={'id_original':'id_reg'})
MANO = pd.read_csv(r'C:\Users\56966\Dropbox\BIDMapuche\data\processed\SAMPLE\SAMPLE_TMD\correcion_a_mano.csv'
                    ).drop_duplicates(subset=['id_original','id_travel','year'], keep='first').rename(columns={'id_original':'id_reg'})
codes = pd.read_csv(r'C:\Users\56966\Dropbox\BIDMapuche\data\processed\ID_OWNERS\codes_owners.csv'
                    )[['id_reg','undefined','mapuche']].rename(columns={'id_reg':'id_travel'})

MATCH = MATCH.loc[~MATCH['id_reg'].isin(MANO['id_reg'])]
MATCH = pd.concat([MATCH, MANO])
del MANO
MATCH = MATCH.merge(codes , how='left', on='id_travel')
MATCH['share'] = np.where((MATCH['share']>=1), 1, MATCH['share'])
MATCH['fallo'] = ( (MATCH['undefined'].isna()) & (MATCH['mapuche'].isna()) ).astype(int)
MATCH['nuevo_fallo'] = MATCH.groupby('id_reg')['fallo'].transform('max')
MATCH = MATCH.loc[MATCH['nuevo_fallo']!=1].drop(columns=['fallo','nuevo_fallo'])
for variables in ['mapuche','undefined']:
    MATCH[f'{variables}_x'] = MATCH[f'{variables}'] * MATCH['share']
    MATCH[f'{variables}_r'] = MATCH[[f'{variables}_x','year','id_reg']].groupby(['id_reg','year']).transform('sum')
MATCH = MATCH.drop_duplicates(subset=['id_reg','year'])[['id_reg', 'year','mapuche_r', 'undefined_r']].rename(
    columns={'mapuche_r':'mapuche', 'undefined_r':'undefined'}
)    
MATCH['otros'] = 1 - MATCH['undefined'] - MATCH['mapuche']

MATCH['mapuche'] = MATCH['mapuche'] / (MATCH['mapuche']+MATCH['otros']) 

df = MATCH.merge(df, how='left', on='id_reg', indicator='first_merge')
df = df.loc[df['first_merge']=='both']

df = df.loc[df['year']!=2024].drop_duplicates(subset=['id_reg','year'])
df['conteo'] = df.groupby('id_reg')['id_reg'].transform('count')

directory = 'REPLACE' if replace == 1 else 'NO_REPLACE'
df.to_stata(rf'C:\Users\56966\Dropbox\BIDMapuche\data\processed\SAMPLE\SAMPLE_TMD\SAMPLE_1\REG{directory}_{directory_2}.dta')

MATCH = pd.read_csv(r'C:\Users\56966\Dropbox\BIDMapuche\data\processed\SAMPLE\SAMPLE_TMD\TDM_post_match.csv'
                    ).drop_duplicates(subset=['id_original','id_travel','year'], keep='first').rename(columns={'id_original':'id_reg'})
MANO = pd.read_csv(r'C:\Users\56966\Dropbox\BIDMapuche\data\processed\SAMPLE\SAMPLE_TMD\correcion_a_mano.csv'
                    ).drop_duplicates(subset=['id_original','id_travel','year'], keep='first').rename(columns={'id_original':'id_reg'})
MATCH = MATCH.loc[~MATCH['id_reg'].isin(MANO['id_reg'])]
MATCH = pd.concat([MATCH, MANO]).drop_duplicates(subset=['id_reg','id_travel','year'])
del MANO

MATCH['q_properties'] = MATCH.groupby(['id_reg', 'year'])['id_travel'].transform('count')
matcher = MATCH.drop_duplicates(subset=['year','id_reg'])[['year','id_reg','q_properties']]
df = pd.read_stata(rf'C:\Users\56966\Dropbox\BIDMapuche\data\processed\SAMPLE\SAMPLE_TMD\SAMPLE_1\REG{directory}_{directory_2}.dta')
df = df.merge(matcher, how='left',
                on=['id_reg','year'])

df.drop(columns=['level_0'], errors='ignore'
        ).to_stata(rf'C:\Users\56966\Dropbox\BIDMapuche\data\processed\SAMPLE\SAMPLE_TMD\SAMPLE_1\REG{directory}_{directory_2}.dta')
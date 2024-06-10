#!/usr/bin/env python

# --------------------------------------------------------------------------------------------------------------------------------------
# File: clasificar_imagen_v5.py
# By Julio Alberto Lascano http://drcalambre.blogspot.com/
#________          _________        .__                ___.                  
#\______ \_______  \_   ___ \_____  |  | _____    _____\_ |_________   ____  
# |    |  \_  __ \ /    \  \/\__  \ |  | \__  \  /     \| __ \_  __ \_/ __ \ 
# |    `   \  | \/ \     \____/ __ \|  |__/ __ \|  Y Y  \ \_\ \  | \/\  ___/ 
#/_______  /__|     \______  (____  /____(____  /__|_|  /___  /__|    \___  >
#        \/                \/     \/          \/      \/    \/            \/ 
# --------------------------------------------------------------------------------------------------------------------------------------
# Last modified:2024-05-30
# --------------------------------------------------------------------------------------------------------------------------------------
# Descripción del script: clasificar_imagen_v5.py
# Carga la imagen y define la región inferior de la misma.
# --------------------------------------------------------------------------------------------------------------------------------------
# Segmentación basada en color en la región inferior y luminosidad promedio de la región inferior:
# --------------------------------------------------------------------------------------------------------------------------------------
# Realiza una segmentación basada en color en la región inferior para identificar ciertos tonos o rangos de color.
# Calcula la luminosidad promedio de la región inferior y de la región donde se detecta un color específico.
# Basándose en la luminosidad promedio y la presencia de color específico, decide si la marca de agua debe ser blanca o negra.
# Imprime el resultado (blanco o negro) junto con la luminosidad promedio de la región inferior.
# --------------------------------------------------------------------------------------------------------------------------------------
# cv2
# --------------------------------------------------------------------------------------------------------------------------------------
# La biblioteca cv2, o OpenCV (Open Source Computer Vision Library), es una biblioteca popular de código abierto diseñada para 
# la visión por computadora y el procesamiento de imágenes. Ofrece una amplia gama de funciones y algoritmos que permiten realizar 
# una variedad de tareas relacionadas con el procesamiento de imágenes y la visión por computadora.
# --------------------------------------------------------------------------------------------------------------------------------------
# NumPy
# --------------------------------------------------------------------------------------------------------------------------------------
# NumPy es una biblioteca fundamental en Python para computación científica y numérica. Proporciona un objeto de matriz 
# multidimensional, junto con una variedad de funciones para operar en estas matrices.
# NumPy se utiliza específicamente para calcular la media (np.mean) y la desviación estándar (np.std) de la luminosidad del color detectado
# en la región inferior de la imagen. Estas estadísticas se utilizan luego para ajustar dinámicamente el valor del umbral para decidir si 
# aplicar una marca de agua blanca o negra.
# --------------------------------------------------------------------------------------------------------------------------------------


import sys
import cv2
import numpy as np

# Función para calcular la luminosidad promedio de una región de la imagen
def calcular_luminosidad_promedio(region):
    luminosidad = cv2.mean(region)[0]
    return luminosidad

def main():
    # Verificar que se proporcionen los argumentos necesarios
    if len(sys.argv) < 3:
        print("Uso: clasificar_imagen_v5.py <ruta_imagen> <factor_escala>")
        sys.exit(1)

    # Ruta de la imagen proporcionada como argumento
    ruta_imagen = sys.argv[1]

    # Definir el factor de escala proporcionado como argumento
    try:
        FACTOR_ESCALA = float(sys.argv[2])
    except ValueError:
        print("El factor de escala debe ser un número.")
        sys.exit(1)

    # Cargar la imagen
    img = cv2.imread(ruta_imagen)

    # Verificar si la imagen se cargó correctamente
    if img is None:
        print("Error al cargar la imagen. Verifique la ruta y el formato del archivo.")
        sys.exit(1)

    # Obtener dimensiones de la imagen
    alto, ancho, _ = img.shape

    # Calcular el tamaño del cuadrante a analizar
    #
    # FACTOR_ESCALA se usa para determinar el tamaño del cuadrante a analizar en la imagen. Ese cuadrante es el que ocupara la marca de agua.
    # alto_cuadrante y ancho_cuadrante se calculan como una fracción de las dimensiones de la imagen.
    #
    # Región Inferior Centrada:
    # Las coordenadas (y_inicio, x_inicio) se calculan para centrar el cuadrante horizontalmente y posicionarlo en la parte inferior de la imagen.
    #
    # Segmentación y Análisis:
    # La segmentación basada en color y el cálculo de luminosidad promedio se realizan en esta región inferior centrada.
    # Esto asegura que el análisis se realice en la parte de la imagen donde estará la marca de agua, considerando su posición centrada y tamaño relativo basado en el factor de escala.

    alto_cuadrante = int(alto * FACTOR_ESCALA * 2)
    ancho_cuadrante = int(ancho * FACTOR_ESCALA * 2)

    # Definir las coordenadas del cuadrante inferior centrado
    y_inicio = alto - alto_cuadrante  # Inicio del cuadrante inferior
    x_inicio = (ancho - ancho_cuadrante) // 2  # Centrar horizontalmente

    # Extraer el cuadrante inferior centrado de la imagen
    region_inferior = img[y_inicio:, x_inicio:x_inicio + ancho_cuadrante]

    # Segmentación basada en color en la región inferior de la imagen
    region_inferior_hsv = cv2.cvtColor(region_inferior, cv2.COLOR_BGR2HSV)
    lower_color = (0, 50, 50)  # Define el rango inferior de color HSV
    upper_color = (20, 255, 255)  # Define el rango superior de color HSV
    mask_color = cv2.inRange(region_inferior_hsv, lower_color, upper_color)

    # Calcular la luminosidad promedio del color detectado en la región inferior
    luminosidad_color = calcular_luminosidad_promedio(mask_color)

    # Calcular estadísticas sobre la luminosidad promedio del color
    luminosidad_color_mean = np.mean(luminosidad_color)
    luminosidad_color_std = np.std(luminosidad_color)

    # Ajustar dinámicamente el valor de umbral_color
    umbral_color = luminosidad_color_mean + 2 * luminosidad_color_std  # Por ejemplo, media + 2 * desviación estándar

    # Calcular la luminosidad promedio de la región inferior
    luminosidad_region_inferior = calcular_luminosidad_promedio(region_inferior)

    # Decidir el color de la marca de agua basado en la luminosidad promedio y el umbral dinámico
    
    # El valor de 127 se utiliza como umbral de luminosidad. Este valor se elige arbitrariamente como punto de corte 
    # para distinguir entre regiones relativamente oscuras y regiones relativamente claras en la imagen. 
    # Un valor de 127 corresponde aproximadamente a la mitad del rango de 0 a 255 en el espacio de color de escala de grises, 
    # donde 0 representa el negro absoluto y 255 representa el blanco absoluto.
    # Si la luminosidad promedio de la región inferior es menor o igual a 127, se considera que esta región es relativamente 
    # oscura. En este caso, se asume que una marca de agua blanca sería más visible y contrastaría mejor con el fondo oscuro. 
    # Por lo tanto, se decide aplicar una marca de agua blanca.
    #
    # La variable luminosidad_color_mean contiene la luminosidad promedio del color detectado en la región inferior de la imagen. 
    # Esta región se segmenta en función de ciertos tonos o rangos de color específicos, como se especifica en el código.
    #
    # Umbral dinámicamente ajustado (umbral_color): En lugar de utilizar un umbral estático, como en el caso 
    # de luminosidad_region_inferior <= 127, aquí se calcula y utiliza un umbral dinámico basado en las estadísticas de la 
    # luminosidad del color detectado en la región inferior. Este umbral puede ajustarse según las características específicas de 
    # la imagen en términos de iluminación, tonos de color, etc.
    #
    # Decisión de aplicar marca de agua blanca o negra: Si la luminosidad promedio del color detectado en la región inferior es menor 
    # o igual al umbral dinámicamente ajustado (umbral_color), se considera que esta región es relativamente oscura en términos de color. 
    # En este caso, se asume que una marca de agua blanca sería más visible y contrastaría mejor con el fondo oscuro. 
    # Por lo tanto, se decide aplicar una marca de agua blanca.
    #
    # Adaptabilidad del umbral dinámico: Al calcular el umbral dinámicamente en función de las estadísticas de la luminosidad del color 
    # detectado, se mejora la adaptabilidad del proceso de decisión a diferentes condiciones de iluminación y variaciones en los tonos de
    # color de la imagen.
    
    if luminosidad_region_inferior <= 127 and luminosidad_color_mean <= umbral_color:
        resultado_color = "blanco"
    else:
        resultado_color = "negro"

    # Imprimir el resultado y la luminosidad
    print(resultado_color, luminosidad_region_inferior)

if __name__ == "__main__":
    main()

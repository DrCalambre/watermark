#!/bin/bash

# --------------------------------------------------------------------------------------------------------------------------------------
# File: aplicar_marca_agua.sh
# By Julio Alberto Lascano http://drcalambre.blogspot.com/
#________          _________        .__                ___.                  
#\______ \_______  \_   ___ \_____  |  | _____    _____\_ |_________   ____  
# |    |  \_  __ \ /    \  \/\__  \ |  | \__  \  /     \| __ \_  __ \_/ __ \ 
# |    `   \  | \/ \     \____/ __ \|  |__/ __ \|  Y Y  \ \_\ \  | \/\  ___/ 
#/_______  /__|     \______  (____  /____(____  /__|_|  /___  /__|    \___  >
#        \/                \/     \/          \/      \/    \/            \/ 
# --------------------------------------------------------------------------------------------------------------------------------------
# Last modified:2024-06-10
# --------------------------------------------------------------------------------------------------------------------------------------
# Descripción del script: aplicar_marca_agua.sh
# --------------------------------------------------------------------------------------------------------------------------------------
# Uso: aplicar_marca_agua.sh -b [marca_agua_blanca] -n [marca_agua_negra] -d [directorio_imagenes] -s [factor_escala] -o [directorio_salida]
# --------------------------------------------------------------------------------------------------------------------------------------
# Este script automatiza el proceso de aplicar una marca de agua a todas las imágenes en un directorio especificado.
# A continuación se explica paso a paso lo que hace el script:
#
# 1. Verificación de comandos de ImageMagick:
#    - Se verifica si los comandos 'identify', 'convert' y 'composite' están disponibles.
#
# 2. Definición de parámetros:
#    - MARCA_DE_AGUA_BLANCA: Ruta de la imagen que se utilizará como marca de agua blanca.
#    - MARCA_DE_AGUA_NEGRA: Ruta de la imagen que se utilizará como marca de agua negra.
#    - DIRECTORIO_IMAGENES: Directorio que contiene las imágenes a las que se aplicará la marca de agua.
#    - FACTOR_ESCALA: Factor de escala que determina el tamaño proporcional de la marca de agua en relación con el ancho de la imagen original.
#    - DIRECTORIO_SALIDA: Directorio donde se guardarán las imágenes con la marca de agua aplicada.
#
# 3. Verificación de parámetros y rutas:
#    - Se verifica que todos los parámetros necesarios se han proporcionado.
#    - Se verifica que las rutas de las marcas de agua y el directorio de imágenes existen.
#    - Si el directorio de salida no existe, se crea automáticamente.
#
# 4. Bucle para procesar cada imagen:
#    - Se utiliza un bucle 'for' para iterar sobre cada archivo en el directorio de imágenes especificado.
#    - Se verifica si el archivo actual en el bucle es un archivo regular utilizando la condición 'if [ -f "$IMAGEN" ]'.
#
# 5. Obtención del tamaño de la imagen:
#    - Se utiliza el comando 'identify' para obtener el tamaño de la imagen en píxeles.
#
# 6. Cálculo del tamaño de la marca de agua:
#    - Se calcula el tamaño de la marca de agua proporcional al tamaño de la imagen original, utilizando el factor de escala definido.
#
# 7. Redimensionamiento de la marca de agua:
#    - Se redimensiona la marca de agua al tamaño calculado y se elimina cualquier perfil de color incrustado para evitar advertencias.
#
# 8. Aplicación de la marca de agua:
#    - Se aplica la marca de agua al pie de la imagen con un margen inferior centrado utilizando el comando 'composite'.
#
# 9. Eliminación de archivos temporales:
#    - Se elimina el archivo temporal de la marca de agua redimensionada después de aplicarla a la imagen.
# --------------------------------------------------------------------------------------------------------------------------------------


# Verificación de comandos de ImageMagick
if ! command -v identify &> /dev/null || ! command -v convert &> /dev/null || ! command -v composite &> /dev/null
then
    echo "ImageMagick no está instalado o los comandos necesarios no están disponibles. Por favor, instálalo antes de ejecutar este script."
    exit 1
fi

# Manejo de errores
# Se añade manejo de errores para asegurar que el script se detenga si ocurre algún problema. 
# Se hace con: set -e lo que hace que el script termine si algún comando falla.

set -e

# Uso: aplicar_marca_agua.sh -b [marca_agua_blanca] -n [marca_agua_negra] -d [directorio_imagenes] -s [factor_escala] -o [directorio_salida]
while getopts "b:n:d:s:o:" opt; do
    case ${opt} in
        b ) MARCA_DE_AGUA_BLANCA=$OPTARG ;;
        n ) MARCA_DE_AGUA_NEGRA=$OPTARG ;;
        d ) DIRECTORIO_IMAGENES=$OPTARG ;;
        s ) FACTOR_ESCALA=$OPTARG ;;
        o ) DIRECTORIO_SALIDA=$OPTARG ;;
        \? ) echo "Uso: aplicar_marca_agua.sh -b [marca_agua_blanca] -n [marca_agua_negra] -d [directorio_imagenes] -s [factor_escala] -o [directorio_salida]"
             exit 1 ;;
    esac
done

# Verificación de parámetros
if [ -z "$MARCA_DE_AGUA_BLANCA" ] || [ -z "$MARCA_DE_AGUA_NEGRA" ] || [ -z "$DIRECTORIO_IMAGENES" ] || [ -z "$FACTOR_ESCALA" ] || [ -z "$DIRECTORIO_SALIDA" ]; then
    echo ""
    echo "Uso: aplicar_marca_agua.sh -b [marca_agua_blanca] -n [marca_agua_negra] -d [directorio_imagenes] -s [factor_escala] -o [directorio_salida]"
    echo ""
    echo "Todos los parámetros (-b, -n, -d, -s, -o) son obligatorios."
    echo "-------------------------------------------------------------------------------------------------------------"
    echo "Factor de escala para el tamaño de la marca de agua -s [factor_escala]"
    echo "Por ejemplo: -s 0.15 , un factor de escala del 15% es adecuado para la fotografia de paisajes."
    echo "-------------------------------------------------------------------------------------------------------------"
    exit 1
fi

# Verificación de la existencia de las rutas de las marcas de agua
if [ ! -f "$MARCA_DE_AGUA_BLANCA" ]; then
    echo "La ruta de la marca de agua blanca ($MARCA_DE_AGUA_BLANCA) no existe."
    exit 1
fi

if [ ! -f "$MARCA_DE_AGUA_NEGRA" ]; then
    echo "La ruta de la marca de agua negra ($MARCA_DE_AGUA_NEGRA) no existe."
    exit 1
fi

# Verificación de la existencia del directorio de imágenes
if [ ! -d "$DIRECTORIO_IMAGENES" ]; then
    echo "El directorio de imágenes ($DIRECTORIO_IMAGENES) no existe."
    exit 1
fi

# Verificación de la existencia del directorio de salida
if [ ! -d "$DIRECTORIO_SALIDA" ]; then
    echo "El directorio de salida ($DIRECTORIO_SALIDA) no existe. Creando el directorio..."
    mkdir -p "$DIRECTORIO_SALIDA"
fi

# Obtener el directorio del script Bash
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Ruta del script Python relativo al directorio del script Bash
SCRIPT_PATH="$SCRIPT_DIR/scripts/clasificar_imagen_v5.py"

# Verificar que el script Python exista
if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "El script $SCRIPT_PATH no existe. Verifica la ruta."
  exit 1
fi

contador=0
tiempo_inicio=$(date +%s)

# Aplicar marca de agua a cada imagen en el directorio
for IMAGEN in "$DIRECTORIO_IMAGENES"/*; do
    if [ -f "$IMAGEN" ] && file --mime-type "$IMAGEN" | grep -q -E "image/(png|gif|jpeg|jpg)"; then
        nombre_imagen=$(basename "$IMAGEN")
        
        # La expresión ${nombre_imagen##*.} utiliza un mecanismo de expansión de parámetros en el shell 
        # de Unix para extraer la extensión de un nombre de archivo.
        # Significa eliminar todo hasta el último punto en el nombre del archivo, y devolver lo que queda.
        
        
        extension_imagen="${nombre_imagen##*.}"
        
        # Obtener el tamaño de la imagen (ancho x altura)
        tamano_imagen=$(identify -format "%wx%h" "$IMAGEN")
        
        # Separar el ancho y la altura
        ancho_imagen=$(echo "$tamano_imagen" | cut -d'x' -f 1)
        altura_imagen=$(echo "$tamano_imagen" | cut -d'x' -f 2)
        
        # Calcular el tamaño de la marca de agua proporcional al tamaño de la imagen
        tamano_marca=$(echo "$ancho_imagen * $FACTOR_ESCALA" | bc)
        
        # Llamada al script de Python para determinar el color (blanco o negro)
        resultados=$(python "$SCRIPT_PATH" "$DIRECTORIO_IMAGENES/$nombre_imagen" "$FACTOR_ESCALA")
        
        # Imprimir los resultados
        
        # Leer los resultados separados
		read -r resultado_color luminosidad <<< "$resultados"
		        
        # Imprimir el resultado capturado para depuración
        
		echo "-------------------------------"
		echo "Color marca de agua: $resultado_color"
		echo "Luminosidad: $luminosidad"
		echo "-------------------------------"
		echo "Aplicando marca de agua a $DIRECTORIO_IMAGENES$nombre_imagen -> $DIRECTORIO_SALIDA${nombre_imagen%.*}_wm.$extension_imagen"

        # Seleccionar la marca de agua según el color determinado
        case "$resultado_color" in
            "blanco")
                MARCA_DE_AGUA=$MARCA_DE_AGUA_BLANCA
                ;;
            "negro")
                MARCA_DE_AGUA=$MARCA_DE_AGUA_NEGRA
                ;;
            *)
                echo "Color desconocido: $color. Usando la marca de agua blanca por defecto."
                MARCA_DE_AGUA=$MARCA_DE_AGUA_BLANCA
                ;;
        esac
        
     
        # Redimensionar la marca de agua al tamaño calculado y eliminar el perfil de color
        # Crear un archivo temporal
        marca_de_agua_redimensionada=$(mktemp)
        convert "$MARCA_DE_AGUA" -resize "${tamano_marca}x${tamano_marca}" -strip "$marca_de_agua_redimensionada"
        
        # Aplicar marca de agua al pie de la imagen con margen inferior centrado
        composite -dissolve 50% -gravity South -geometry +0+50   "$marca_de_agua_redimensionada" "$IMAGEN" "$DIRECTORIO_SALIDA/${nombre_imagen%.*}_wm.$extension_imagen"
        
        # Eliminar el archivo temporal de la marca de agua redimensionada
        rm "$marca_de_agua_redimensionada"
        
        # Incrementar el contador por cada imagen procesada
		contador=$((contador + 1))
        
    fi
done

# Calcular el tiempo total transcurrido
tiempo_fin=$(date +%s)
tiempo_total=$((tiempo_fin - tiempo_inicio))

# Convertir tiempo total a formato hh:mm:ss
horas=$((tiempo_total / 3600))
minutos=$(( (tiempo_total % 3600) / 60 ))
segundos=$((tiempo_total % 60))

# Mostrar el total de imágenes procesadas y el tiempo que tomó
echo "Total de imágenes procesadas: $contador"
# Formatear la salida
printf "Tiempo total transcurrido: %02d:%02d:%02d\n" $horas $minutos $segundos

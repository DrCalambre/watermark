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
# Last modified:2024-06-19
# --------------------------------------------------------------------------------------------------------------------------------------
# Descripción del script: aplicar_marca_agua.sh
# --------------------------------------------------------------------------------------------------------------------------------------
# Este script automatiza el proceso de aplicar una marca de agua a todas las imágenes en un directorio especificado.
# A continuación se explica paso a paso lo que hace el script:
#
# 1. Verificación de comandos de ImageMagick:
#    - Se verifica si los comandos 'identify', 'convert' y 'composite' están disponibles.

# Verificación de comandos de ImageMagick
if ! command -v identify &> /dev/null || ! command -v convert &> /dev/null || ! command -v composite &> /dev/null; then
    echo "ImageMagick no está instalado o los comandos necesarios no están disponibles. Por favor, instálalo antes de ejecutar este script."
    exit 1
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

# Ruta de imagen about
IMG_PATH="$SCRIPT_DIR/pics/20181125_102821_wm.jpg"

# Verificar que el script Python exista
if [[ ! -f "$IMG_PATH" ]]; then
  echo "Ruta de imagen about $IMG_PATH no existe. Verifica la ruta."
  exit 1
fi

# Diálogo about:
yad --picture --title="Watermark - Programa de marcas de agua - Copyright © 2024 Julio Alberto Lascano" \
 --center \
 --size=fit \
 --width=800 \
 --height=450 \
 --filename="$IMG_PATH" \
 --button=gtk-ok:0


# Declarar las variables como globales
declare -g MARCA_DE_AGUA_BLANCA
declare -g MARCA_DE_AGUA_NEGRA
declare -g DIRECTORIO_IMAGENES
declare -g DIRECTORIO_SALIDA
declare -g FACTOR_ESCALA

# Crear un archivo temporal para almacenar los datos para ser mostrados en resumen final con yad
temp_file=$(mktemp)


# Función para contar la cantidad de imágenes en un directorio
contar_imagenes() {
    local directorio=$1
    local count=0
    
    for archivo in "$directorio"/*; do
        if file --mime-type "$archivo" | grep -q -E "image/(png|gif|jpeg|jpg)"; then
            count=$((count + 1))
        fi
    done
    
    echo $count
}

# Función para solicitar directorios al usuario
solicitar_directorios() {
    # Seleccionar la marca de agua blanca
    while true; do
		MARCA_DE_AGUA_BLANCA=$(yad --center --file --title="Seleccione marca de agua color blanco." --add-preview --image-filter=png --button=gtk-cancel:1 --button=gtk-ok:0)
		
		# Verificar si el usuario seleccionó una marca de agua
		if [ ! -f "$MARCA_DE_AGUA_BLANCA" ]; then
			yad --center --text="Debe seleccionar una marca de agua de color blanco."
		else
			break
		fi
	done
	
	# Seleccionar la marca de agua negra
    while true; do
		MARCA_DE_AGUA_NEGRA=$(yad --center --file --title="Seleccione marca de agua color negro." --add-preview --image-filter=png --button=gtk-cancel:1 --button=gtk-ok:0)
		
		# Verificar si el usuario seleccionó una marca de agua
		if [ ! -f "$MARCA_DE_AGUA_NEGRA" ]; then
			yad --center --text="Debe seleccionar una marca de agua de color negro."
		else
			break
		fi
	done
	
	# Seleccionar el directorio de imágenes
    while true; do
		DIRECTORIO_IMAGENES=$(yad --center --file --title="Seleccione carpeta de imágenes" --directory --button=gtk-cancel:1 --button=gtk-ok:0)
		
		
		# Verificar si el usuario canceló la selección directorio de imágenes
        if [ -z "$DIRECTORIO_IMAGENES" ]; then
            yad --center --text="Debe seleccionar un directorio de imágenes."
        else
			break
		fi
	done
	
	# Seleccionar el directorio de salida
    while true; do
		DIRECTORIO_SALIDA=$(yad --center --file --title="Seleccione carpeta de salida" --directory --button=gtk-cancel:1 --button=gtk-ok:0)
		
		# Verificar si el usuario canceló la selección directorio de imágenes
        if [ -z "$DIRECTORIO_SALIDA" ]; then
            yad --center --text="Debe seleccionar un directorio de salida."
		fi
		
		# Verificar que el directorio de salida no sea el mismo que el directorio de imágenes
        if [ "$DIRECTORIO_SALIDA" = "$DIRECTORIO_IMAGENES" ]; then
            yad --center --text="El directorio de salida no puede ser el mismo que el directorio de imágenes. Por favor, seleccione un directorio diferente."
        else
            break
        fi
	done
	
	# Seleccionar el factor de escala
	while true; do
		FACTOR_ESCALA=$(yad --center --scale --width=300 --min-value=15 --max-value=100 --step=5 --title="% Escala Marca de agua")
		
		# Verificar si el usuario canceló la selección del factor de escala
        if [ -z "$FACTOR_ESCALA" ]; then
            yad --center --text="Debe seleccionar un factor de escala."
        else
			break
		fi
	done
	
	# Dividir el valor de FACTOR_ESCALA por 100 con una presición de dos decimales
    FACTOR_ESCALA=$(echo "scale=2; $FACTOR_ESCALA / 100" | bc)
    
	# Mostrar los valores seleccionados y preguntar si son correctos
	yad --form --title="Confirmar Selección" --center \
--width=800 \
--field="Marca de Agua blanca:":RO $(basename "$MARCA_DE_AGUA_BLANCA") \
--field="Marca de Agua negra:":RO $(basename "$MARCA_DE_AGUA_NEGRA") \
--field="Directorio de Imágenes:":RO $DIRECTORIO_IMAGENES \
--field="Directorio de Salida:":RO $DIRECTORIO_SALIDA \
--field="Factor de Escala:":RO $FACTOR_ESCALA \
--button="No:1" \
--button="Si:0"
	
    return $?
}
# Inicializar la confirmación a un valor que no sea 0
CONFIRMACION=1

# Bucle para solicitar rutas hasta que el usuario confirme los valores
while [ $CONFIRMACION -ne 0 ]
do
	solicitar_directorios
	CONFIRMACION=$?
done

# Contar la cantidad de imágenes en el directorio de imágenes
CANTIDAD_DE_IMAGENES=$(contar_imagenes "$DIRECTORIO_IMAGENES")

echo "Marca de Agua blanca: $MARCA_DE_AGUA_BLANCA"
echo "Marca de Agua negra: $MARCA_DE_AGUA_NEGRA"
echo "Directorio de Imágenes: $DIRECTORIO_IMAGENES"
echo "Directorio de Salida: $DIRECTORIO_SALIDA"
echo "Factor de Escala: $FACTOR_ESCALA"
echo "Cantidad de Imágenes: $CANTIDAD_DE_IMAGENES"


contador=0
tiempo_inicio=$(date +%s)

# Aplicar marca de agua a cada imagen en el directorio
for IMAGEN in "$DIRECTORIO_IMAGENES"/*; do
   if [ -f "$IMAGEN" ] && file --mime-type "$IMAGEN" | grep -q -E "image/(png|gif|jpeg|jpg)"; then
        nombre_imagen=$(basename "$IMAGEN")
        
        # Incrementar el contador por cada imagen procesada
		contador=$((contador + 1))        
        
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
        
        # Leer los resultados separados
		read -r resultado_color luminosidad <<< "$resultados"
		
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
     
        # Crear un archivo temporal para resumen final con yad
        marca_de_agua_redimensionada=$(mktemp)

        # Redimensionar la marca de agua al tamaño calculado y eliminar el perfil de color
        convert "$MARCA_DE_AGUA" -resize "${tamano_marca}x${tamano_marca}" -strip "$marca_de_agua_redimensionada"
        
        # Calcula el progreso actual para yad --progress
		progress=$(( (contador * 100) / CANTIDAD_DE_IMAGENES ))

		# Actualiza la barra de progreso (valor numérico) de yad --progress
		echo $progress
		
		# formatear luminosidad a 2 decimales
		formatted=$(awk -v num="$luminosidad" 'BEGIN { printf "%.2f\n", num }')
		
        # Escribir los datos en archivo temporal para ser mostrados en resumen final con yad
        echo "${nombre_imagen%.*}_wm.$extension_imagen $resultado_color $formatted" >> "$temp_file"
        
        # log de cuadro de diálogo yad --progress
        echo "# ${nombre_imagen%.*}_wm.$extension_imagen - Luminosidad:$formatted -> color marca:$resultado_color - ($contador de $CANTIDAD_DE_IMAGENES)"
        
        # Aplicar marca de agua al pie de la imagen con margen inferior centrado
        composite -dissolve 50% -gravity South -geometry +0+50   "$marca_de_agua_redimensionada" "$IMAGEN" "$DIRECTORIO_SALIDA/${nombre_imagen%.*}_wm.$extension_imagen"
        
        # Eliminar el archivo temporal de la marca de agua redimensionada
        rm "$marca_de_agua_redimensionada"
        
    fi 
done | yad --progress --title="Progreso para $CANTIDAD_DE_IMAGENES imágenes"  --enable-log="Procesando ahora..." --text="Aplicando marcas." --center --log-height=100 --width=600 --button=gtk-ok --log-expanded --auto-kill
 

# Calcular el tiempo total transcurrido
tiempo_fin=$(date +%s)
tiempo_total=$((tiempo_fin - tiempo_inicio))

# Convertir tiempo total a formato hh:mm:ss
horas=$((tiempo_total / 3600))
minutos=$(( (tiempo_total % 3600) / 60 ))
segundos=$((tiempo_total % 60))

# Formatear la salida
printf "Tiempo total transcurrido: %02d:%02d:%02d\n" $horas $minutos $segundos
tiempo=$(printf "%02d:%02d:%02d\n" $horas $minutos $segundos)

# Mostrar resumen
yad --center --height=200 --width=600 --title="Resumen" --form \
--field="Total de imágenes procesadas":RO "$CANTIDAD_DE_IMAGENES" \
--field="Factor de Escala":RO "$FACTOR_ESCALA" \
--field="Directorio de Salida":RO "$DIRECTORIO_SALIDA" \
--field="Tiempo total transcurrido":RO "$tiempo" \
--button=gtk-ok


# Comando awk para formatear los datos del archivo temporal
file_content=$(awk '{print $1 "\t" $2 "\t" $3}' "$temp_file")

# Construir el comando yad con los elementos del archivo temporal
yad --list \
--width=450 \
--height=400 \
--center \
--title="Luminosidad y color - $CANTIDAD_DE_IMAGENES imágenes" \
--column="Archivo" \
--column="Color marca" \
--column="Luminosidad" \
--text="Resultados" \
-- $file_content
    
# Eliminar el archivo temporal después de usarlo
rm "$temp_file"

start="${1:-0}"
upperlim="${2:-1}"

#DRIVE="lambda-root.ext4"
DRIVE="rootfs.ext4"

for ((i=start; i<upperlim; i++)); do
  echo $i
  cp $DRIVE ${DRIVE}-sb"$i" 
done


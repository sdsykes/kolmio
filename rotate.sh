for i in 1 2 3 4 5 6 7 8 9
do
  convert -background transparent -rotate -120 P"$i"_0.png -crop "300x259+37-65" P"$i"_1.png
  convert -background transparent -rotate 120 P"$i"_0.png -crop "300x259-37-65" P"$i"_2.png
done

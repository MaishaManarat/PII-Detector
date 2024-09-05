-----------PII Detector To Detect Potential PII Data Existance in Database-----------

For Data Privacy/Cybersecurity Officers to Detect and Mark Sensitive Databases

The code is written in python. Python3 is required. Change the contents of the keyword file as needed

This code is written as such, it connectes to a db server and checks fields of every table of every database and match to the keyword list. For example we are checking for phonenumber in databases, it will check every table and match fields name with phonenumber. The result will show pii detected or not. If Pii is detected it will return first 5 rows of the table to give user better view on the data.

This code will work for remote servers as well, as long as connectivity to the remote server has been establised.

The limitation of the code is that it only matches keywords with fields. So if someone saves phonenumber on a column titles pikuchan and it is not on the keywordlist, then the code will not detect the pii data. [ The possible solution for this limitation is either pattern matching (which is also limiting as different kind of pattern matching script will be needed for differnt kind pii data) or using machine learning/AI ]


>>>The code can be improved significantly by using Machine Learning. Next Target !(•̀ᴗ•́)و ̑̑



/// got hella lot of help from gemini ◦°˚\(*❛ ‿ ❛)/˚°◦

/\︵-︵/\
 |(◉)=(◉)|
  \ ︶V︶ /
 /↺↺ ↺↺\
|↺↺↺↺↺|
 \↺↺ ↺↺/
 ¯¯/\¯/\¯¯




.....

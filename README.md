## California Assembly and Senate Roll Call Vote Data, 1993 to the present

This project provides ready-to-analyze roll call voting data from the California Assembly and Senate from 1993 to present. The data from the current session are updated weekly. The datasets are constructed from files provided at [ftp://leginfo.ca.gov/pub](ftp://leginfo.ca.gov/pub).

A tutorial on how to load and analyze these data using R can be found here. 

Zip archives are provided for each two-year session. Each zip file contains two files:

`caYY-YYvotes.dat`: A fix-width format file of all votes cast by every member of both chambers in committee and on the floor.  Each row in the file represents a given member.  The columns 1 through 25 contain the the name the member.  Each of the remaining columns shows the member's vote on each rollcall call taken.  The votes are recorded as: 1 = 'Yea', 6	= 'No', 9	= 'Not voting/not present', 0	= 'Not in chamber or not on committee'.

`caYY-YYdesc.dat`: A tab separated file describing the location, sponsor, content, and outcome of each vote taken. The fields are the following:
1. Vote column in the vote matrix
2. Bill number
3. Sponsor/Author
4. Topic
5. Date
6. Location
7. Motion
8. Yeas
9. Noes
10.	Pass/Fail

**Note**: The rollcall data matrices are large as they include every vote taken in both chambers including both committee and floor votes. The state changed the manner in which it posts the votes in 2016, so you might see some differnences in the codings of committee names and so forth starting in 2017.

These data are provided without guarantee of their accuracy. Please feel free to point out any problems that you might find. Please attribute these data to me if you use them in your work and send links to the working papers and publications that use these data.  

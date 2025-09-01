// Real officials data with actual email addresses  
// Complete dataset of 148 officials with emails and phone numbers

class OfficialData {
  final String displayName;
  final String email;

  OfficialData({required this.displayName, required this.email});
}

class OfficialsDataProvider {
  static List<OfficialData> getAllOfficials() {
    const csvData = '''Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373,aldridge_brandon@ymail.com
Certified,8,Aldridge,Eldlondro,28 Hi Pointe dr,Belleville,62223,618-960-1071,ejaldridge90@yahoo.com
Registered,3,Angleton,Darrell,800 Alton St,Alton,62002,618-792-9995,ltc.angle@gmail.com
Recognized,5,Armstrong,Dennis,1505 Keck Ridge Dr,O'Fallon,62269,269-876-6008,redman_00_2001@yahoo.com
Recognized,11,Baird,Robert,1217 W Woodfield Dr,Alton,62002,618-401-4016,rbaird@stambrosegodfrey.org
Certified,12,Barczewski,Paul,414 E Park Ln.,Nashville,62263,618-314-5349,paulb@notslogistics.com
Registered,3,Becton,Brandon,5966 Sherry Ave,St Louis,63136,314-978-7712,bbecton36@gmail.com
Certified,36,Belcher,Brian,PO Box 166,Coulterville,62237,618-967-5081,bbelcher34@gmail.com
Certified,16,Bicanic,Louis,4 Ridgefield Ct,Maryville,62062,618-973-9484,lbicanic@sbcglobal.net
Registered,26,Bishop,David,P.O. Box 412,Greenfield,62044,217-370-2851,davidbishop2005@yahoo.com
Registered,2,Blacharczyk,Matt,17 Bourdelais Drive,Belleville,62226,618-830-4165,matt.blacharczyk32@gmail.com
Recognized,8,Blakemore,Michael,PO Box 94,O'Fallon,62269,618-363-4625,mikebmore@yahoo.com
Registered,3,Boykin,Theatrice,387 Sweetwater Lane,O'Fallon,62269,314-749-8245,Theatriceboykin@gmail.com
Certified,28,Broadway,James,4502  Broadway Acres Dr.,Glen Carbon,62034,618-781-7110,1jimbroadway@gmail.com
Registered,3,Brooks,Terry,878 Torino Drive,Ballwin,63021,314-348-9920,tabrooks1956@yahoo.com
Registered,2,Brown,Keyshawn,168 Liberty Dr,Belleville,62226,618-509-7375,Keyshawn.brown345@gmail.com
Recognized,4,Brunstein,Nick,364 Jubaka Dr,Fairview Heights,62208,618-401-5301,nbrunstein62@gmail.com
Certified,30,Buckley,James,2723 Bryden Ct.,Alton,62002,618-606-2217,jamesbuckleylaw@yahoo.com
Certified,19,Bundy,Ryan,1405 Stonebrooke Drive,Edwardsville,62025,618-210-0257,rbundy84@hotmail.com
Certified,41,Bussey,William,12703 Meadowdale Dr,St. Louis,63138,314-406-8685,amanta30@aol.com
Recognized,4,Cain,Jonathan,14 Thornhurst Ct,Columbia ,62236,618-581-9275,tylercain3@gmail.com
Certified,8,Carmack,Jay,116 Brackett Street,Swansea,62226,618-541-0012,jrcarmack55@icloud.com
Certified,8,Carmack,Jeff,112 Westview Drive,Freeburg,62243,618-580-1310,jeffcarmack@att.net
Certified,7,Carpenter,Don,233 Cedar St,Eldred,62027,217-248-4489,doncarp@hotmail.com
Certified,44,Chapman,Ralph,6563 State Rt 127,Pinckneyville,62274,618-923-0733,rcpro89@gmail.com
Registered,13,Clark,James,3056 Indian Medows Lane,Edwardsville,62025,618-558-5095,jclark@winsupplyinc.com
Certified,6,Clymer,Roger,144 N 1400 E Road,Nokomis,62075,618-409-1868,rclymer@prairiefarms.com
Registered,3,Colbert,Aiden,920 Hamburg Ln,Millstadt,62260,618-606-1924,colbertaiden620@gmail.com
Registered,2,Colbert,Craig,22 Rose Ct,Glen Carbon,62034,618-660-5455,ccolbert_1998@yahoo.com
Certified,14,Cole,Bobby,119 Fox Creek Road,Belleville,62223,618-974-0035,bobbyjcolesr08@yahoo.com
Recognized,9,Cornell,Curtis,912 Stone Creek Ln,Belleville,62223,314-306-0453,curtis_cornell@yahoo.com
Certified,18,Cowan,Clint,317 North Meadow Lane,Steeleville,62288,618-615-1079,cowan3680@gmail.com
Registered,21,Crain,Daniel,721 N. Main St.,Breese,62230,618-550-8152,dancrain@juno.com
Registered,1,Crump,Scott,210 Shawnee Dr.,Wood River,62095,618-972-8406,scottcrump27@gmail.com
Certified,29,Curtis,Raymond,609 Marian Street,Dupo,62239,618-477-0590,curtis2112@charter.net
Recognized,7,Dale,Bobby,7008 Fairbanks St,O'Fallon,62269,314-920-7457,bldale@yahoo.com
Certified,11,Dalman,Patrick,218 Shoreline Dr Unit 3,O'Fallon,62269,618-520-0440,patdalman@att.net
Certified,24,Davis,Chad,Po  Box 133,Maryville,62062,618-799-3496,chad-davis@att.net
Registered,8,DeClue,Wayman,440 Miranda Dr.,Dupo,62239,618-980-3368,wayjac1@yahoo.com
Registered,3,Dederich,Peter,1001 S. Wood St.,Staunton,62088,309-530-9920,FFBPeterD@gmail.com
Registered,3,Dintelmann,Paul,112 Lake Forest Dr,Belleville,62220,619-415-3786,p.dintelmann@gmail.com
Registered,4,Dooley,Chad,607 N Jackson St,Litchfield,62056,217-556-4096,dooleychad@hotmail.com
Registered,1,Dunderdale,Josh,7044 Bellingham,OFallon,62269,618-363-1172,jdunderdale@hotmail.com
Recognized,5,Dunevant,Keith,405 Adams Drive,Waterloo,62298,618-340-8578,dunevantkeith@gmail.com
Registered,14,Dunnette,Brian,2720 Stone Valley Drive,Maryville,62062,618-514-9897,Briandunnette@icloud.com
Certified,26,Eaves,Michael,2548 Stratford Ln.,Granite City,62040,618-830-5829,maeaves@charter.net
Certified,27,Ferguson,Eric,701 Clinton St,Gillespie,62033,217-276-3314,eferguson13@aol.com
Registered,3,Fox,Malcolm,6 Clinton Hill Dr,Swansea,62226,314-240-6115,mfoxjr1985@gmail.com
Registered,1,Gasawski,Gary,34 Lindenleaf Ln,Belleville,62223,618-567-0273,gasawski19@yahoo.com
Certified,21,George,Louis,106 West Cherry,Hartford,62048,618-789-6553,lougeor28@gmail.com
Registered,2,George,Peyton,203 Arrowhead Dr,Troy,62294,618-960-1421,peytongeorge7@gmail.com
Certified,30,George,Ricky,203 Arrowhead Dr.,Troy,62294,618-567-6862,cprgeorge@yahoo.com
Certified,10,Gerlach,Andy,505 Ridge Ave.,Steeleville,62288,618-534-2429,agerlach@egyptian.net
Registered,3,Gibson,Troy,860 Longfellow ave.,Wood River,62095,618-520-4869,troygibson.home@gmail.com
Certified,29,Gray,Jason,3405 Amber Meadows Court,Swansea,62226,618-550-8663,ofishee8@gmail.com
Certified,12,Greenfield,Beaux,204 Wild Cherry Ln.,Swansea,62226,618-540-8911,Beauxgreenfield@yahoo.com
Certified,12,Greenfield,Derek,9 Josiah Ln.,Millstadt,62260,618-604-6944,greenfield.derek86@gmail.com
Certified,51,Harre,Larry,597 E. Fairview Ln.,Nashville,62263,555-555-5555,dianaharre2@hotmail.com
Certified,26,Harris,Jeffrey,103 North 41st St.,Belleville,62226,618-979-8209,elmo_1106@yahoo.com
Certified,21,Harris,Nathan,2551 London Lane,Belleville,62221,618-791-2945,nsharris21@yahoo.com
Registered,3,Harshbarger,Andrew,2309 Woodlawn Ave,Granite City,62040,618-910-7492,ajharshbarger@yahoo.com
Recognized,5,Haywood,Kim,218 Locust Dr.,Shiloh,62269,618-960-2627,kjhaywood6@yahoo.com
Certified,7,Hennessey,James,313 Sleeping Indian Dr.,Freeburg,62243,618-623-5759,jhennessey27@gmail.com
Registered,2,Henry,Tim,117 Rhinegarten Dr,Hazelwood,63031,618-558-4923,ILLTIMHENRY@GMAIL.COM
Recognized,9,Heyen,Matthew,1615 N State St,Litchfield,62056,217-313-4421,Mattjr16@hotmail.com
Certified,32,Hinkamper,Roy,14 Fox Trotter Ct,High Ridge,63049,314-606-8598,royhinkamper@hotmail.com
Certified,14,Holder,David,805 Charles Court,Steeleville,62288,618-615-1663,holderd74@yahoo.com
Certified,43,Holshouser,Robert,1083 Prestonwood Dr.,Edwardsville,62025,618-407-1824,bhols1975@gmail.com
Registered,4,Holtkamp,Jacob,336 Lincolnshire Blvd,Belleville,62221,618-322-8966,jakeholtkamp93@gmail.com
Registered,4,Hudson,Lamont,341 Frey Lane,Fairview Heights,62208,708-724-8642,lamontthudson@yahoo.com
Certified,22,Hughes,Ramonn,748 North 40th St.,East St. Louis,62205,314-651-2010,ump2004@gmail.com
Certified,11,Jackson,Brian,1137 Hampshire Lane,Shiloh,62221,618-301-0975,jacksonb03@gmail.com
Certified,20,Jenkins,Darren,8825 Wendell Creek Dr.,St. Jacob,62281,618-977-9311,papawams@yahoo.com
Certified,27,Johnson,Emric,245 Americana Circle,Fairview Heights,62208,618-979-7221,emjjoh8@myyahoo.com
Recognized,18,Kaiser,Joseph,302 Bridle Ridge,Collinsville,62234,618-616-6632,jgkaiser@sbcglobal.net
Certified,15,Kamp,Jeffrey,958 Auer Landing Rd,Golden Eagle,62036,618-467-6060,jdkamp@myyahoo.com
Certified,36,Kampwerth,Daniel,900 Pioneer Ct.,Breese,62230,618-363-0685,dkampwerth@firstfederalmascoutah.com
Certified,47,Lang,Louis,612 E. Main St.,Coffeen,62017,217-246-2549,langltll@hotmail.com
Certified,25,Lashmett,Dan,1834 Lakamp Rd,Roodhouse,62082,217-473-2046,DJLashmett@gmail.com
Recognized,7,Lawson,Justin,228 e lincoln st,White Hall,62092,217-883-7083,justincards22@gmail.com
Certified,26,Lee,Darin,2818 Woodfield drive,Maryville,62062,618-977-1568,coachlee@cusd.kahoks.org
Registered,3,Lentz,James,3811 State Route 160,Highland,62249,618-444-1773,lentz818@yahoo.com
Recognized,9,Leonard,Bill,249 SE 200 Ave,Carrollton,62016,618-946-2266,carrhawks6@gmail.com
Certified,36,Levan,Scott,72 Heatherway Dr,Wood River,62095,618-444-0256,levan.scott@charter.net
Certified,29,Lewis,Willie,1100 Summit Ave,East St. Louis,62201,618-407-5733,wlewis43@aol.com
Recognized,11,Lutz,Michael,1307 Allendale,Chester,62233,618-615-1194,piddle1976@gmail.com
Registered,2,Marifian,John,32 Suzanne Dr.,Smithton,62285,310-779-4388,marif5@verizon.net
Registered,8,McAnulty,William,1123 Eagle LN,Grafton,62037,618-610-9344,wmcanulty@hotmail.com
Registered,2,McCracken,Shane,1106 North Idler Lane,Greenville,62246,618-699-9063,smccracken141@gmail.com
Recognized,8,McKay,Geoffery,1516 Gedern Drive,Columbia,62236,314-973-9561,gmckay1313@gmail.com
Registered,2,Mckinney,Jon,1401 Exchange Ave,East St. Louis,62205,618-271-3857,chrismckinney341@gmail.com
Registered,7,Middleton,Timothy,900 Ottawa Ct,Mascoutah,62258,850-758-7278,tmidd77@icloud.com
Certified,14,Modarelli,Michael,7920 West A Streeet,Belleville,62223,314-322-9359,mike37new@gmail.com
Registered,5,Morris,Deon,5710 Cates Ave,Saint Louis,63112,314-393-7464,Dcmorris82@gmail.com
Registered,3,Morris,Ranesha,5710 Cates Ave,Saint Louis,63112,314-458-4245,rdmorris80@hmail.com
Certified,40,Morrisey,James,106 Oakridge Estates Dr.,Glen Carbon,62034,618-444-0232,morriseyjc@yahoo.com
Certified,24,Mueller,Larry,2745 Otten Rd,Millstadt,62260,618-660-9394,umpjkl4953@att.net
Certified,23,Murray,Johnny,2 Madonna Ct,Belleville,62223,618-235-5196,jmurray47@att.net
Certified,10,Nichols,Kevin,224 Centennial St,White Hall,62092,217-248-8745,kdn1098@yahoo.com
Certified,16,Ohren,Blake,115 Baneberry Dr.,Highland,62249,618-971-9037,Bohren27@gmail.com
Registered,4,Owens,Jacoy,143 Perrottet Dr,Mascoutah,62258,580-301-2646,jacoy.owens.1@gmail.com
Certified,11,Pearce,Allan,303 Quarry Street,Staunton,62088,847-217-0922,al.pearce@att.net
Registered,2,Phillips,Arthur,1595 Paddock Dr.,Florissant,63033,402-981-5532,Bigart32@gmail.com
Certified,19,Phillips,Jacob,510 Florence Avenue ,Dupo,62239,618-830-6378,cub2000@hotmail.com
Certified,32,Phillips,Michael,4539 Little Rock Rd. Apt. K,St. Louis,63128,314-805-8381,umpirmic@gmail.com
Registered,3,Pizzo,Isaac,618 N. Franklin St,Litchfield,62056,217-851-1890,ipizzo@live.com
Certified,14,Pollard,Jason,1032 Meadow Lake Drive,Maryville,62062,618-830-7979,jason.pollard45@gmail.com
Certified,8,Potillo,Justin,18046 Stagecoach Rd,Jerseyville,62052,618-556-7375,justin.potillo@gmail.com
Recognized,5,Powell,John,629 Solomon St.,Chester,62233,815-641-6074,powell1326@gmail.com
Certified,30,Purcell,Trent,1110 Madison Dr.,Carlyle,62231,618-401-1950,tpurcell2205@att.net
Certified,17,Raney,Michael,50 Cheshire Dr ,Belleville,62223,618-402-5717,turtleraney4457@yahoo.com
Certified,21,Rathert,Charles,3138 Bluff Rd,Edwardsville,62025,314-303-8044,chuckrathert@gmail.com
Certified,13,Rathert,Joe,3120 Bluff Road,Edwardsville,62025,555-555-5555,joerathert@gmail.com
Certified,21,Reif,Timothy,333 9th Street,Carrollton,62016,217-473-9321,timfreif@gmail.com
Certified,16,Roberts,Nathan,525 N Main St,White Hall,62092,217-473-2906,nroberts33@msn.com
Registered,14,Roundtree,Shawn,11 Jennifer Dr,Glen Carbon,62034,618-789-2451,iroundtree@aol.com
Registered,6,Royer,Justin,317 W South St,Mascoutah,62258,618-401-8671,jroyer74@hotmail.com
Registered,2,Royer,Riley,317 W South St.,Mascoutah,62258,618-406-4748,rileyroyer07@gmail.com
Registered,2,Sanders,Justin,219 Vale Dr.,Fairview Heights,62208,618-250-3598,justinsanders19@yahoo.com
Certified,37,Schaaf,Donald,1462 South Lake Drive,Carrollton,62016,618-535-6435,dschaaf@gtec.com
Certified,14,Schipper,Dennis,2424 Persimmon Wood Dr,Belleville,62221,618-772-9909,dennis.schipper.1@us.af.mil
Recognized,14,Schmitz,Jason,85 Sunfish Dr.,Highland,62249,618-792-2923,schmitz.jasone@gmail.com
Registered,5,Scroggins,Louie,29 Scroggins Lane,Hillsboro,62049,217-556-0403,dawn31@consolidated.net
Registered,5,Scurlark,James,117 Pierce Blvd,O'Fallon,62269,618-977-6568,scurlark20@gmail.com
Certified,15,Seibert,Tracy,9903 Old Lincoln Trail,Fairview Heights,62208,618-531-0029,CCSEIBERT95@YAHOO.COM
Certified,27,Sheff,Ronald,363 East Airline Dr.,East Alton,62024,618-610-7117,ronsheff11@yahoo.com
Recognized,12,Shofner,Alan,1878 Franklin Hill RD,Batchtown,62006,618-535-9590,ashofner@calhoun40.net
Certified,20,Silas,Andre,520 Washington St.,Venice,62090,217-341-0597,Silas1Bradshaw@yahoo.com
Registered,1,Slater,Jaidan,503 Tunsion Ave,White Hall,62092,217-271-7145,jaidanslater23@gmail.com
Registered,10,Smail,Donovan,500 W Fairground Avenue,Hillsboro,62049,217-820-1550,donvansmail113@gmail.com
Registered,3,Smith-Raschen,Sarah,7364 Kindlewood Dr.,Edwardsville,62025,618-593-0834,sdsmith.raschen@gmail.com
Certified,24,Speciale,Andrew,5B Villa Ct.,Edwardsville,62025,314-587-9902,aspeciale@polsinelli.com
Certified,20,Stinemetz,Douglas,616 W Bottom Ave.,Columbia,62236,618-719-6173,djstine@htc.net
Recognized,4,Stuller,Nathan,303 Collinsville Road,Troy,62294,618-304-4011,nathan.stuller@tcusd2.org
Certified,14,Swank,Shawn,301 W Spruce,Gillespie,62033,217-556-5066,sswank92@gmail.com
Registered,2,Taylor,Dorion,131 Skyline View Dr.,Collinsville,62234,618-207-7998,coachdtaylor86@gmail.com
Certified,29,Thomas,Carl,228 Springdale Dr,Belleville,62223,618-781-8225,officialcthomas@gmail.com
Certified,31,Tolle,Richard,511 N. Main,Witt,62094,217-556-9441,parts1957@hotmail.com
Certified,21,Trotter,Benjamin,1228 Conrad Ln,O'Fallon,62269,618-779-4372,btrotter53@gmail.com
Certified,26,Unverzagt,Jason,307 N. 39 St,Belleville,62226,555-555-5555,bjunvy29@gmail.com
Certified,11,Walters,Chris,1211 Marshal Ct,O'Fallon,62269,217-549-8844,chris.walters906@gmail.com
Registered,8,Warrer,Jackson,4555 Zika Ln,Edwardsville,62025,618-920-9681,jbwarrior15@gmail.com
Recognized,14,Warrer,Scott,4555 Zika Lane,Edwardsville,62025,618-920-2141,buckeyewarrior65@aol.com
Certified,26,Webster,Vincent,2 Lakeshire Dr.,Fairview Hts.,62208,618-660-7107,vwebster1960@yahoo.com
Certified,6,Womack,Paul,811 S Polk St.,Millstadt,62260,618-567-7609,P.womack@sbcglobal.net
Recognized,7,Wood,William,2764 Staunton Road,Troy,62294,618-593-5617,cwood1128@gmail.com
Certified,17,Wooten,Edward,801 Chancellor Dr,Edwardsville,62025,618-560-1502,ewooten24@gmail.com
Recognized,8,Wyatt,Nick,620 Mor St,Gillespie,62033,217-851-3662,wyattnick12@gmail.com''';

    List<OfficialData> officials = [];

    // Parse CSV data
    final lines = csvData.trim().split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Parse CSV line with proper quote handling
      final parts = _parseCSVLine(line);
      if (parts.length >= 9) {
        // Format: Level of Certification,Years of Experience,Last Name,First Name,Address,City,ZIP,Phone,Email
        final lastName = parts[2].trim();
        final firstName = parts[3].trim();
        final email = parts[8].trim();

        // Generate display name in "J. Smith" format
        final displayName = '${firstName[0]}. $lastName';

        officials.add(OfficialData(displayName: displayName, email: email));
      }
    }

    return officials;
  }

  // Get the raw CSV data for use by seeder
  static String getCsvData() {
    return '''Certified,8,Aldridge,Brandon,2627 Columbia Lakes Drive Unit 2D,Columbia,62236,618-719-4373,aldridge_brandon@ymail.com
Certified,8,Aldridge,Eldlondro,28 Hi Pointe dr,Belleville,62223,618-960-1071,ejaldridge90@yahoo.com
Registered,3,Angleton,Darrell,800 Alton St,Alton,62002,618-792-9995,ltc.angle@gmail.com
Recognized,5,Armstrong,Dennis,1505 Keck Ridge Dr,O'Fallon,62269,269-876-6008,redman_00_2001@yahoo.com
Recognized,11,Baird,Robert,1217 W Woodfield Dr,Alton,62002,618-401-4016,rbaird@stambrosegodfrey.org
Certified,12,Barczewski,Paul,414 E Park Ln.,Nashville,62263,618-314-5349,paulb@notslogistics.com
Registered,3,Becton,Brandon,5966 Sherry Ave,St Louis,63136,314-978-7712,bbecton36@gmail.com
Certified,36,Belcher,Brian,PO Box 166,Coulterville,62237,618-967-5081,bbelcher34@gmail.com
Certified,16,Bicanic,Louis,4 Ridgefield Ct,Maryville,62062,618-973-9484,lbicanic@sbcglobal.net
Registered,26,Bishop,David,P.O. Box 412,Greenfield,62044,217-370-2851,davidbishop2005@yahoo.com
Registered,2,Blacharczyk,Matt,17 Bourdelais Drive,Belleville,62226,618-830-4165,matt.blacharczyk32@gmail.com
Recognized,8,Blakemore,Michael,PO Box 94,O'Fallon,62269,618-363-4625,mikebmore@yahoo.com
Registered,3,Boykin,Theatrice,387 Sweetwater Lane,O'Fallon,62269,314-749-8245,Theatriceboykin@gmail.com
Certified,28,Broadway,James,4502  Broadway Acres Dr.,Glen Carbon,62034,618-781-7110,1jimbroadway@gmail.com
Registered,3,Brooks,Terry,878 Torino Drive,Ballwin,63021,314-348-9920,tabrooks1956@yahoo.com
Registered,2,Brown,Keyshawn,168 Liberty Dr,Belleville,62226,618-509-7375,Keyshawn.brown345@gmail.com
Recognized,4,Brunstein,Nick,364 Jubaka Dr,Fairview Heights,62208,618-401-5301,nbrunstein62@gmail.com
Certified,30,Buckley,James,2723 Bryden Ct.,Alton,62002,618-606-2217,jamesbuckleylaw@yahoo.com
Certified,19,Bundy,Ryan,1405 Stonebrooke Drive,Edwardsville,62025,618-210-0257,rbundy84@hotmail.com
Certified,41,Bussey,William,12703 Meadowdale Dr,St. Louis,63138,314-406-8685,amanta30@aol.com
Recognized,4,Cain,Jonathan,14 Thornhurst Ct,Columbia ,62236,618-581-9275,tylercain3@gmail.com
Certified,8,Carmack,Jay,116 Brackett Street,Swansea,62226,618-541-0012,jrcarmack55@icloud.com
Certified,8,Carmack,Jeff,112 Westview Drive,Freeburg,62243,618-580-1310,jeffcarmack@att.net
Certified,7,Carpenter,Don,233 Cedar St,Eldred,62027,217-248-4489,doncarp@hotmail.com
Certified,44,Chapman,Ralph,6563 State Rt 127,Pinckneyville,62274,618-923-0733,rcpro89@gmail.com
Registered,13,Clark,James,3056 Indian Medows Lane,Edwardsville,62025,618-558-5095,jclark@winsupplyinc.com
Certified,6,Clymer,Roger,144 N 1400 E Road,Nokomis,62075,618-409-1868,rclymer@prairiefarms.com
Registered,3,Colbert,Aiden,920 Hamburg Ln,Millstadt,62260,618-606-1924,colbertaiden620@gmail.com
Registered,2,Colbert,Craig,22 Rose Ct,Glen Carbon,62034,618-660-5455,ccolbert_1998@yahoo.com
Certified,14,Cole,Bobby,119 Fox Creek Road,Belleville,62223,618-974-0035,bobbyjcolesr08@yahoo.com
Recognized,9,Cornell,Curtis,912 Stone Creek Ln,Belleville,62223,314-306-0453,curtis_cornell@yahoo.com
Certified,18,Cowan,Clint,317 North Meadow Lane,Steeleville,62288,618-615-1079,cowan3680@gmail.com
Registered,21,Crain,Daniel,721 N. Main St.,Breese,62230,618-550-8152,dancrain@juno.com
Registered,1,Crump,Scott,210 Shawnee Dr.,Wood River,62095,618-972-8406,scottcrump27@gmail.com
Certified,29,Curtis,Raymond,609 Marian Street,Dupo,62239,618-477-0590,curtis2112@charter.net
Recognized,7,Dale,Bobby,7008 Fairbanks St,O'Fallon,62269,314-920-7457,bldale@yahoo.com
Certified,11,Dalman,Patrick,218 Shoreline Dr Unit 3,O'Fallon,62269,618-520-0440,patdalman@att.net
Certified,24,Davis,Chad,Po  Box 133,Maryville,62062,618-799-3496,chad-davis@att.net
Registered,8,DeClue,Wayman,440 Miranda Dr.,Dupo,62239,618-980-3368,wayjac1@yahoo.com
Registered,3,Dederich,Peter,1001 S. Wood St.,Staunton,62088,309-530-9920,FFBPeterD@gmail.com
Registered,3,Dintelmann,Paul,112 Lake Forest Dr,Belleville,62220,619-415-3786,p.dintelmann@gmail.com
Registered,4,Dooley,Chad,607 N Jackson St,Litchfield,62056,217-556-4096,dooleychad@hotmail.com
Registered,1,Dunderdale,Josh,7044 Bellingham,OFallon,62269,618-363-1172,jdunderdale@hotmail.com
Recognized,5,Dunevant,Keith,405 Adams Drive,Waterloo,62298,618-340-8578,dunevantkeith@gmail.com
Registered,14,Dunnette,Brian,2720 Stone Valley Drive,Maryville,62062,618-514-9897,Briandunnette@icloud.com
Certified,26,Eaves,Michael,2548 Stratford Ln.,Granite City,62040,618-830-5829,maeaves@charter.net
Certified,27,Ferguson,Eric,701 Clinton St,Gillespie,62033,217-276-3314,eferguson13@aol.com
Registered,3,Fox,Malcolm,6 Clinton Hill Dr,Swansea,62226,314-240-6115,mfoxjr1985@gmail.com
Registered,1,Gasawski,Gary,34 Lindenleaf Ln,Belleville,62223,618-567-0273,gasawski19@yahoo.com
Certified,21,George,Louis,106 West Cherry,Hartford,62048,618-789-6553,lougeor28@gmail.com
Registered,2,George,Peyton,203 Arrowhead Dr,Troy,62294,618-960-1421,peytongeorge7@gmail.com
Certified,30,George,Ricky,203 Arrowhead Dr.,Troy,62294,618-567-6862,cprgeorge@yahoo.com
Certified,10,Gerlach,Andy,505 Ridge Ave.,Steeleville,62288,618-534-2429,agerlach@egyptian.net
Registered,3,Gibson,Troy,860 Longfellow ave.,Wood River,62095,618-520-4869,troygibson.home@gmail.com
Certified,29,Gray,Jason,3405 Amber Meadows Court,Swansea,62226,618-550-8663,ofishee8@gmail.com
Certified,12,Greenfield,Beaux,204 Wild Cherry Ln.,Swansea,62226,618-540-8911,Beauxgreenfield@yahoo.com
Certified,12,Greenfield,Derek,9 Josiah Ln.,Millstadt,62260,618-604-6944,greenfield.derek86@gmail.com
Certified,51,Harre,Larry,597 E. Fairview Ln.,Nashville,62263,555-555-5555,dianaharre2@hotmail.com
Certified,26,Harris,Jeffrey,103 North 41st St.,Belleville,62226,618-979-8209,elmo_1106@yahoo.com
Certified,21,Harris,Nathan,2551 London Lane,Belleville,62221,618-791-2945,nsharris21@yahoo.com
Registered,3,Harshbarger,Andrew,2309 Woodlawn Ave,Granite City,62040,618-910-7492,ajharshbarger@yahoo.com
Recognized,5,Haywood,Kim,218 Locust Dr.,Shiloh,62269,618-960-2627,kjhaywood6@yahoo.com
Certified,7,Hennessey,James,313 Sleeping Indian Dr.,Freeburg,62243,618-623-5759,jhennessey27@gmail.com
Registered,2,Henry,Tim,117 Rhinegarten Dr,Hazelwood,63031,618-558-4923,ILLTIMHENRY@GMAIL.COM
Recognized,9,Heyen,Matthew,1615 N State St,Litchfield,62056,217-313-4421,Mattjr16@hotmail.com
Certified,32,Hinkamper,Roy,14 Fox Trotter Ct,High Ridge,63049,314-606-8598,royhinkamper@hotmail.com
Certified,14,Holder,David,805 Charles Court,Steeleville,62288,618-615-1663,holderd74@yahoo.com
Certified,43,Holshouser,Robert,1083 Prestonwood Dr.,Edwardsville,62025,618-407-1824,bhols1975@gmail.com
Registered,4,Holtkamp,Jacob,336 Lincolnshire Blvd,Belleville,62221,618-322-8966,jakeholtkamp93@gmail.com
Registered,4,Hudson,Lamont,341 Frey Lane,Fairview Heights,62208,708-724-8642,lamontthudson@yahoo.com
Certified,22,Hughes,Ramonn,748 North 40th St.,East St. Louis,62205,314-651-2010,ump2004@gmail.com
Certified,11,Jackson,Brian,1137 Hampshire Lane,Shiloh,62221,618-301-0975,jacksonb03@gmail.com
Certified,20,Jenkins,Darren,8825 Wendell Creek Dr.,St. Jacob,62281,618-977-9311,papawams@yahoo.com
Certified,27,Johnson,Emric,245 Americana Circle,Fairview Heights,62208,618-979-7221,emjjoh8@myyahoo.com
Recognized,18,Kaiser,Joseph,302 Bridle Ridge,Collinsville,62234,618-616-6632,jgkaiser@sbcglobal.net
Certified,15,Kamp,Jeffrey,958 Auer Landing Rd,Golden Eagle,62036,618-467-6060,jdkamp@myyahoo.com
Certified,36,Kampwerth,Daniel,900 Pioneer Ct.,Breese,62230,618-363-0685,dkampwerth@firstfederalmascoutah.com
Certified,47,Lang,Louis,612 E. Main St.,Coffeen,62017,217-246-2549,langltll@hotmail.com
Certified,25,Lashmett,Dan,1834 Lakamp Rd,Roodhouse,62082,217-473-2046,DJLashmett@gmail.com
Recognized,7,Lawson,Justin,228 e lincoln st,White Hall,62092,217-883-7083,justincards22@gmail.com
Certified,26,Lee,Darin,2818 Woodfield drive,Maryville,62062,618-977-1568,coachlee@cusd.kahoks.org
Registered,3,Lentz,James,3811 State Route 160,Highland,62249,618-444-1773,lentz818@yahoo.com
Recognized,9,Leonard,Bill,249 SE 200 Ave,Carrollton,62016,618-946-2266,carrhawks6@gmail.com
Certified,36,Levan,Scott,72 Heatherway Dr,Wood River,62095,618-444-0256,levan.scott@charter.net
Certified,29,Lewis,Willie,1100 Summit Ave,East St. Louis,62201,618-407-5733,wlewis43@aol.com
Recognized,11,Lutz,Michael,1307 Allendale,Chester,62233,618-615-1194,piddle1976@gmail.com
Registered,2,Marifian,John,32 Suzanne Dr.,Smithton,62285,310-779-4388,marif5@verizon.net
Registered,8,McAnulty,William,1123 Eagle LN,Grafton,62037,618-610-9344,wmcanulty@hotmail.com
Registered,2,McCracken,Shane,1106 North Idler Lane,Greenville,62246,618-699-9063,smccracken141@gmail.com
Recognized,8,McKay,Geoffery,1516 Gedern Drive,Columbia,62236,314-973-9561,gmckay1313@gmail.com
Registered,2,Mckinney,Jon,1401 Exchange Ave,East St. Louis,62205,618-271-3857,chrismckinney341@gmail.com
Registered,7,Middleton,Timothy,900 Ottawa Ct,Mascoutah,62258,850-758-7278,tmidd77@icloud.com
Certified,14,Modarelli,Michael,7920 West A Streeet,Belleville,62223,314-322-9359,mike37new@gmail.com
Registered,5,Morris,Deon,5710 Cates Ave,Saint Louis,63112,314-393-7464,Dcmorris82@gmail.com
Registered,3,Morris,Ranesha,5710 Cates Ave,Saint Louis,63112,314-458-4245,rdmorris80@hmail.com
Certified,40,Morrisey,James,106 Oakridge Estates Dr.,Glen Carbon,62034,618-444-0232,morriseyjc@yahoo.com
Certified,24,Mueller,Larry,2745 Otten Rd,Millstadt,62260,618-660-9394,umpjkl4953@att.net
Certified,23,Murray,Johnny,2 Madonna Ct,Belleville,62223,618-235-5196,jmurray47@att.net
Certified,10,Nichols,Kevin,224 Centennial St,White Hall,62092,217-248-8745,kdn1098@yahoo.com
Certified,16,Ohren,Blake,115 Baneberry Dr.,Highland,62249,618-971-9037,Bohren27@gmail.com
Registered,4,Owens,Jacoy,143 Perrottet Dr,Mascoutah,62258,580-301-2646,jacoy.owens.1@gmail.com
Certified,11,Pearce,Allan,303 Quarry Street,Staunton,62088,847-217-0922,al.pearce@att.net
Registered,2,Phillips,Arthur,1595 Paddock Dr.,Florissant,63033,402-981-5532,Bigart32@gmail.com
Certified,19,Phillips,Jacob,510 Florence Avenue ,Dupo,62239,618-830-6378,cub2000@hotmail.com
Certified,32,Phillips,Michael,4539 Little Rock Rd. Apt. K,St. Louis,63128,314-805-8381,umpirmic@gmail.com
Registered,3,Pizzo,Isaac,618 N. Franklin St,Litchfield,62056,217-851-1890,ipizzo@live.com
Certified,14,Pollard,Jason,1032 Meadow Lake Drive,Maryville,62062,618-830-7979,jason.pollard45@gmail.com
Certified,8,Potillo,Justin,18046 Stagecoach Rd,Jerseyville,62052,618-556-7375,justin.potillo@gmail.com
Recognized,5,Powell,John,629 Solomon St.,Chester,62233,815-641-6074,powell1326@gmail.com
Certified,30,Purcell,Trent,1110 Madison Dr.,Carlyle,62231,618-401-1950,tpurcell2205@att.net
Certified,17,Raney,Michael,50 Cheshire Dr ,Belleville,62223,618-402-5717,turtleraney4457@yahoo.com
Certified,21,Rathert,Charles,3138 Bluff Rd,Edwardsville,62025,314-303-8044,chuckrathert@gmail.com
Certified,13,Rathert,Joe,3120 Bluff Road,Edwardsville,62025,555-555-5555,joerathert@gmail.com
Certified,21,Reif,Timothy,333 9th Street,Carrollton,62016,217-473-9321,timfreif@gmail.com
Certified,16,Roberts,Nathan,525 N Main St,White Hall,62092,217-473-2906,nroberts33@msn.com
Registered,14,Roundtree,Shawn,11 Jennifer Dr,Glen Carbon,62034,618-789-2451,iroundtree@aol.com
Registered,6,Royer,Justin,317 W South St,Mascoutah,62258,618-401-8671,jroyer74@hotmail.com
Registered,2,Royer,Riley,317 W South St.,Mascoutah,62258,618-406-4748,rileyroyer07@gmail.com
Registered,2,Sanders,Justin,219 Vale Dr.,Fairview Heights,62208,618-250-3598,justinsanders19@yahoo.com
Certified,37,Schaaf,Donald,1462 South Lake Drive,Carrollton,62016,618-535-6435,dschaaf@gtec.com
Certified,14,Schipper,Dennis,2424 Persimmon Wood Dr,Belleville,62221,618-772-9909,dennis.schipper.1@us.af.mil
Recognized,14,Schmitz,Jason,85 Sunfish Dr.,Highland,62249,618-792-2923,schmitz.jasone@gmail.com
Registered,5,Scroggins,Louie,29 Scroggins Lane,Hillsboro,62049,217-556-0403,dawn31@consolidated.net
Registered,5,Scurlark,James,117 Pierce Blvd,O'Fallon,62269,618-977-6568,scurlark20@gmail.com
Certified,15,Seibert,Tracy,9903 Old Lincoln Trail,Fairview Heights,62208,618-531-0029,CCSEIBERT95@YAHOO.COM
Certified,27,Sheff,Ronald,363 East Airline Dr.,East Alton,62024,618-610-7117,ronsheff11@yahoo.com
Recognized,12,Shofner,Alan,1878 Franklin Hill RD,Batchtown,62006,618-535-9590,ashofner@calhoun40.net
Certified,20,Silas,Andre,520 Washington St.,Venice,62090,217-341-0597,Silas1Bradshaw@yahoo.com
Registered,1,Slater,Jaidan,503 Tunsion Ave,White Hall,62092,217-271-7145,jaidanslater23@gmail.com
Registered,10,Smail,Donovan,500 W Fairground Avenue,Hillsboro,62049,217-820-1550,donvansmail113@gmail.com
Registered,3,Smith-Raschen,Sarah,7364 Kindlewood Dr.,Edwardsville,62025,618-593-0834,sdsmith.raschen@gmail.com
Certified,24,Speciale,Andrew,5B Villa Ct.,Edwardsville,62025,314-587-9902,aspeciale@polsinelli.com
Certified,20,Stinemetz,Douglas,616 W Bottom Ave.,Columbia,62236,618-719-6173,djstine@htc.net
Recognized,4,Stuller,Nathan,303 Collinsville Road,Troy,62294,618-304-4011,nathan.stuller@tcusd2.org
Certified,14,Swank,Shawn,301 W Spruce,Gillespie,62033,217-556-5066,sswank92@gmail.com
Registered,2,Taylor,Dorion,131 Skyline View Dr.,Collinsville,62234,618-207-7998,coachdtaylor86@gmail.com
Certified,29,Thomas,Carl,228 Springdale Dr,Belleville,62223,618-781-8225,officialcthomas@gmail.com
Certified,31,Tolle,Richard,511 N. Main,Witt,62094,217-556-9441,parts1957@hotmail.com
Certified,21,Trotter,Benjamin,1228 Conrad Ln,O'Fallon,62269,618-779-4372,btrotter53@gmail.com
Certified,26,Unverzagt,Jason,307 N. 39 St,Belleville,62226,555-555-5555,bjunvy29@gmail.com
Certified,11,Walters,Chris,1211 Marshal Ct,O'Fallon,62269,217-549-8844,chris.walters906@gmail.com
Registered,8,Warrer,Jackson,4555 Zika Ln,Edwardsville,62025,618-920-9681,jbwarrior15@gmail.com
Recognized,14,Warrer,Scott,4555 Zika Lane,Edwardsville,62025,618-920-2141,buckeyewarrior65@aol.com
Certified,26,Webster,Vincent,2 Lakeshire Dr.,Fairview Hts.,62208,618-660-7107,vwebster1960@yahoo.com
Certified,6,Womack,Paul,811 S Polk St.,Millstadt,62260,618-567-7609,P.womack@sbcglobal.net
Recognized,7,Wood,William,2764 Staunton Road,Troy,62294,618-593-5617,cwood1128@gmail.com
Certified,17,Wooten,Edward,801 Chancellor Dr,Edwardsville,62025,618-560-1502,ewooten24@gmail.com
Recognized,8,Wyatt,Nick,620 Mor St,Gillespie,62033,217-851-3662,wyattnick12@gmail.com''';
  }

  static List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }

    // Add the last field
    result.add(current.toString());

    return result;
  }
}
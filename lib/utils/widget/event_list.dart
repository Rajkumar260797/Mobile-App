import 'package:flutter/material.dart';
import 'package:homegenie/Screen/event_details.dart';

class EventCard extends StatelessWidget {
  final String name;
  final String initials;
  final String title;
  final String eventType;
  final String location;
  final String date;
  final String time;

  const EventCard({
    Key? key,
    required this.name,
    required this.initials,
    required this.title,
    required this.eventType,
    required this.location,
    required this.date,
    required this.time,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width;
    return 
    GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventDetails(eventid: name)),
      );
    },
    child:
    
    Container(
      padding: EdgeInsets.all(12.0),
      margin: EdgeInsets.symmetric(horizontal: 10,vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.blueAccent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(3, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              Container(
                width: cardWidth * 0.15,
                alignment: Alignment.topCenter,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor:  Colors.blueAccent,
                  child: Text(initials, style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                ),
              ),


              Container(
                width: cardWidth *0.58,
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  
                  children: [
                    Text(title, style: TextStyle(fontSize: 14,),maxLines: 2,overflow: TextOverflow.ellipsis,),
                    Text("Event type : $eventType", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),


              Container(
                width: cardWidth * 0.13,
                alignment: Alignment.topRight,
                child: SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetails(eventid: name,)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 216, 216),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text("Open", style: TextStyle(color: Colors.red, fontSize: 10)),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          // Row(
          //   children: [
          //     Icon(Icons.location_pin, color: Colors.blue),
          //     SizedBox(width: 10),
          //     Expanded(child: Text(location, style: TextStyle(fontSize: 14))),
          //   ],
          // ),

          Container(width: double.infinity, height: 2, color: Colors.grey),
          SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Date : $date", style: TextStyle(fontSize: 16)),
              Text("Start By : $time", style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    )
    );
  }
}
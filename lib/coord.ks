// Routines to help deal with coordinates and reference frames.

// Given a Ship-RAW XYZ vector, return its vector meaning in a ref frame
// based on the direction you pass in.
function convert_vec_to_frame {
  parameter
    in_vec, // input vector (in ship-raw XYZ coords)
    frame.  // reference frame (a Direction who's fore,top,star vectors are the axes)

  return v(
    vdot(in_vec, frame:starvector), 
    vdot(in_vec, frame:topvector),
    vdot(in_vec, frame:forevector)
    ).
}


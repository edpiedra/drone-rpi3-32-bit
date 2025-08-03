import cv2 
from typing import Sequence 

class BodyDetector:
    def __init__(self):
        '''
        Creates a BodyDetection object that uses haarcascade filters.
        '''
        self.body_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_fullbody.xml')
        
    def detect_bodies(self, frame: cv2.Mat) -> Sequence[tuple[int]]:
        '''
        Scans a frame for bodies.
        
        Args:
            frame : video frame
        Returns:
            a sequence of tuples with (x, y, w, h) for the location of each body
        '''
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        bodies = self.body_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=3)
        
        return bodies
    
    def get_body_centers(self, bodies: Sequence[tuple[int]]) -> list[tuple[int]]:
        '''
        Returns a list of centers for each body
        
        Args:
            bodies : a sequence of tuples with (x, y, w, h) for the location of each body
        Returns:
            list of tuples with (x, y) for the center of each body
        '''
        centers = []
        
        for (x, y, w, h) in bodies:
            center_x = int((2*x + w)/2)
            center_y = int((2*y + h)/2)
            
            centers.append((center_x, center_y))
            
        return centers    
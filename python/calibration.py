from psychopy import visual, core
from psychopy.visual.windowwarp import Warper
import numpy as np

win = visual.Window([400,400],pos=None,color=(0,0,0),colorSpace='rgb255',useFBO=True)
warper = Warper(win,
                warp='cylindrical',
                warpfile = "",
                warpGridsize = 128,
                eyepoint = [0.5, 0.5],
                flipHorizontal = False,
                flipVertical = False)


dot = visual.Circle(win, radius=0.1, colorSpace='rgb255', pos=(-1,0))
n_frames = 100

for dist in np.linspace(0.1,40,10):
    warper.dist_cm = dist
    warper.changeProjection(warp='cylindrical')
    dot.pos = [-1,0]
    for i in range(n_frames):
        dot.pos += [1/50,0]
        dot.draw()
        win.flip()


win.close()

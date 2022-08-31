classdef visual_stim
    
     properties
        primitives (1,:) visual_primitive
        isi {mustBeNumeric}
        repeats {mustBeNumeric}
        time_shift {mustBeNumeric}
        descr char
        duration {mustBeNumeric}
     end
    
     methods
         function obj = visual_stim(primitives,isi,repeats,time_shift,descr)
             obj.primitives = primitives;
             obj.isi = isi;
             obj.repeats = repeats;
             obj.time_shift = time_shift;
             obj.descr = descr;
             duration = 0;
             for i = 1:numel(primitives)
                duration = max(primitives(i).param(end,1),duration);
             end
             obj.duration = duration;
         end
         
         function movie = create_frames(obj)
             % TODO check if grids are compatible (space and time)
             % for now I just assume that they are but this could 
             % easily break in the future
             % I suggest doing some kind of interpolation in space and 
             % time (interp3) to fix this 
             
             % add movies together 
             movie = [];
             for p = 1:numel(obj.primitives)
                 m = obj.primitives(p).create_frames();
                 if p == 1
                    movie = m;
                 else 
                    movie = movie + m;
                 end
             end
         end
     end
end
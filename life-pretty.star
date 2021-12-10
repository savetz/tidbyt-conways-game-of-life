#Game of Life (with cell aging) for Tidbyt by Kay Savetz
#Dec 10 2021

load("render.star", "render")
load("http.star", "http")
load("re.star", "re")

WIDTH=64
HEIGHT=32

def main():

	#Seed the playfield with random pixels
	#neither Starlark nor the Tidbyt modules provide a random number function(!) so we'll
	#cheat by fetching random numbers from random.org. Info at https://www.random.org/clients/http/
	resp = http.get("https://www.random.org/integers/?num=" + str(WIDTH*HEIGHT) + "&min=0&max=2&col=1&base=10&format=plain&rnd=new")
	if resp.status_code != 200:
		fail("Request failed with status %d", resp.status_code)
	random = resp.body()
	random = re.sub("\n","",random) #squish the numbers into a string of digits

	generation=0
	frames=[]
	new = [[0 for i in range(WIDTH+2)] for j in range(HEIGHT+2)] #blank the playfield
	
	#set up starting board
	counter=0
	for y in range(1,HEIGHT+1):
		for x in range(1,WIDTH+1):
			if(random[counter] == "0"): #seeding a third of the pixels works nicely IMO
				new[y][x] = 1
			counter+=1

	while(generation<1000):

		old = new[0::] #Make a copy of the current playfield.
				#TIL 'old = new' creates an alias, it doesn't make a copy
				#See https://github.com/google/starlark-go/blob/master/doc/spec.md#identity-and-mutation
		new = [[0 for i in range(WIDTH+2)] for j in range(HEIGHT+2)] #blank the playfield
		
		#Life algorithm as described by Mark D. Niemiec in the January 1979 issue of Byte
		#https://archive.org/details/byte-magazine-1979-01/page/n91		
		for y in range(1,HEIGHT+1): #start at 1 because the "edges" of the matrix are always zero
			for x in range(1,WIDTH+1): 
					sum= int(old[y-1][x-1]>0) + int(old[y-1][x]>0) + int(old[y-1][x+1]>0)
					sum+=int(old[y][x-1]>0)   + int(old[y][x+1]>0)
					sum+=int(old[y+1][x-1]>0) + int(old[y+1][x]>0) + int(old[y+1][x+1]>0)
					
					if sum==3:
						if(old[y][x]>=0): #cell was vacant or already alive, now alive or older
							if(old[y][x]<9): #don't age past 9
								new[y][x]=old[y][x]+1
							else:
								new[y][x]=old[y][x] #stay at 9
						else: #cell was previously dead, now alive
							new[y][x]=1
					elif sum==2:
						if(old[y][x]<0): #cell was already dead, now decomposing
							new[y][x]=old[y][x]+1
						elif(old[y][x]>0): #live cell is older
							if(old[y][x]<9): #don't age past 9 
								new[y][x]=old[y][x]+1
							else:
								new[y][x]=old[y][x] #stay at 9
						else:							
							new[y][x]=0 #vacant spot remains vacant
					else: #sum is 0, 1, or >3					
						if(old[y][x]>0): #cell was alive, now newly dead
							new[y][x]=-9
						elif(old[y][x]<0): #cell was already dead, now dead longer
							new[y][x]=old[y][x]+1
						#else:
							#new[y][x]=0 #implied; this is the default because we blanked the new playfield
												
		generation+=1	
		print("Generation " + str(generation))

		frames.append(
			render.Column(
				children=display(new),
			),
		)
		
		if(new==old):
			print("Stasis.")
			break

	print(str(len(frames)) + " frames")
	
	return render.Root(
		delay = 5,
		child = render.Animation(
			children=frames,
		)
	)   

def display(screen):
	screenrow=[]
	for i in range(len(screen)): #change pixels to Box widgets, per horiz line
		screenrow.append([])
		for j in range(1,len(screen[i])): #start at 1 because the "edges" of the matrix are always zero
			cell = screen[i][j]
			if cell == 0: #vacant
				pixelcolor = "#000"
			elif cell < 0: #dead and decomposing
				pixelcolor = "#" + str(-cell) + "00"
			else: #alive and aging
				pixelcolor = "#" + str(9-cell) + str(9-cell) + "F"
			screenrow[i].append (
				render.Box(
						color=pixelcolor,
						width=1, 
						height=1,
				),
			)

	screencol=[]
	for i in range(1,len(screenrow)): #combine lines of Box widgets (the rows of the screen) into columns of Row widgets
		screencol.append(
			render.Row(
				children=screenrow[i],
			),
		)
	
	return screencol

#Game of Life for Tidbyt by Kay Savetz
#Dec 9 2021

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
					sum= old[y-1][x-1] + old[y-1][x] + old[y-1][x+1]
					sum+=old[y][x-1]   + old[y][x+1]
					sum+=old[y+1][x-1] + old[y+1][x] + old[y+1][x+1]
					
					if sum==3:
						new[y][x]=1
					elif sum==2:
						new[y][x]=old[y][x]
					#else:
					#	new[y][x]=0 #implied; this is the default because we blanked the new playfield
						
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
			if screen[i][j] == 0:
				pixelcolor = "#000"
			else:
				pixelcolor = "#0F0"
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

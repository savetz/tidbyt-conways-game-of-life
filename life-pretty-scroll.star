#Game of Life (with cell aging and decay) for Tidbyt by Kay Savetz
#Dec 10 2021

load("render.star", "render")
load("http.star", "http")
load("re.star", "re")

SCREEN_WIDTH=64
SCREEN_HEIGHT=32

X_VELOCITY, Y_VELOCITY = 0.5, 0.5
GENERATIONS = 500
BOARD_WIDTH, BOARD_HEIGHT = 50, 50

def lcg(seed):
	m, a, c = 2 << 31, 1103515245, 12345
	seed = (a * seed + c) % m
	return seed, (a * seed + c) % m

def get(board, x, y):
	return board[y % BOARD_HEIGHT][x % BOARD_WIDTH]

def main():

	resp = http.get("https://www.random.org/integers/?num=1&min=-1000000000&max=1000000000&col=1&base=10&format=plain&rnd=new")
	if resp.status_code != 200:
		fail("Request failed with status %d", resp.status_code)
	seed = int(resp.body().strip())

	generation=0
	frames=[]
	board = [[0 for i in range(BOARD_WIDTH + 2)] for j in range(BOARD_HEIGHT + 2)] #blank the playfield
	view = [[0 for i in range(SCREEN_WIDTH)] for j in range(SCREEN_HEIGHT)]

	#set up starting board
	counter=0
	for y in range(1,BOARD_HEIGHT + 1):
		for x in range(1,BOARD_WIDTH + 1):
			seed, r = lcg(seed)
			if(r % 3 == 0):
				board[y][x] = 1
			counter+=1

	xoff, yoff = 0, 0
	while(generation<GENERATIONS):

		old_board = board[0::] #Make a copy of the current playfield.
				#TIL 'old_board = board' creates an alias, it doesn't make a copy
				#See https://github.com/google/starlark-go/blob/master/doc/spec.md#identity-and-mutation
		board = [[0 for i in range(BOARD_WIDTH+2)] for j in range(BOARD_HEIGHT+2)] #blank the playfield

		#Life algorithm as described by Mark D. Niemiec in the January 1979 issue of Byte
		#https://archive.org/details/byte-magazine-1979-01/page/n91
		for y in range(BOARD_HEIGHT): #start at 1 because the "edges" of the matrix are always zero
			for x in range(BOARD_WIDTH):
					sum= int(get(old_board, x - 1, y - 1) > 0) + int(get(old_board, x, y - 1) > 0) + int(get(old_board, x + 1, y - 1) > 0)
					sum+=int(get(old_board, x - 1, y) > 0) + int(get(old_board, x + 1, y) > 0)
					sum+=int(get(old_board, x - 1, y + 1) > 0) + int(get(old_board, x, y + 1) > 0) + int(get(old_board, x + 1, y + 1) > 0)

					if sum==3:
						if(old_board[y][x]>=0): #cell was vacant or already alive, now alive or older
							if(old_board[y][x]<9): #don't age past 9
								board[y][x]=old_board[y][x]+1
							else:
								board[y][x]=old_board[y][x] #stay at 9
						else: #cell was previously dead, now alive
							board[y][x]=1
					elif sum==2:
						if(old_board[y][x]<0): #cell was already dead, now decomposing
							board[y][x]=old_board[y][x]+1
						elif(old_board[y][x]>0): #live cell is older
							if(old_board[y][x]<9): #don't age past 9
								board[y][x]=old_board[y][x]+1
							else:
								board[y][x]=old_board[y][x] #stay at 9
						else:
							board[y][x]=0 #vacant spot remains vacant
					else: #sum is 0, 1, or >3
						if(old_board[y][x]>0): #cell was alive, now boardly dead
							board[y][x]=-9
						elif(old_board[y][x]<0): #cell was already dead, now dead longer
							board[y][x]=old_board[y][x]+1

		generation+=1
		print("Generation " + str(generation))

		for y in range(SCREEN_HEIGHT):
			for x in range(SCREEN_WIDTH):
				view[y][x] = get(board, x + int(xoff), y + int(yoff))

		frames.append(
			render.Column(
				children=display(view),
			),
		)

		if(board==old_board):
			print("Stasis.")
			break

		xoff += X_VELOCITY
		yoff += Y_VELOCITY

	print(str(len(frames)) + " frames")

	return render.Root(
		delay = 50,
		child = render.Animation(
			children=frames,
		)
	)

def display(screen):
	screenrow=[]
	for i in range(len(screen)): #change pixels to Box widgets, per horiz line
		screenrow.append([])
		for j in range(len(screen[i])): #start at 1 because the "edges" of the matrix are always zero
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
	for i in range(len(screenrow)): #combine lines of Box widgets (the rows of the screen) into columns of Row widgets
		screencol.append(
			render.Row(
				children=screenrow[i],
			),
		)

	return screencol

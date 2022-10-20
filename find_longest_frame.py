import sys, getopt
import os
import operator

def find_frames(filename):
	with open(filename) as f:
		print (filename)
		frames = []
		frame = []
		for line in f.readlines():
			if line[0] == '>':
				frames.append(''.join(frame))
				frame = []
			else:
				frame.append(line.strip('\n'))
		frames.append(''.join(frame))
		frames.pop(0)
	return frames


def find_longest_frame(frames):
	frames_dict = dict()
	for frame in frames:
		start = False
		count = 0
		for letter in frame:
			if letter == 'M' and start == False:
				start = True
				count = 0
			elif letter == '-' and start == True:
				frames_dict[frame] = count
				break
			elif start == True:
				count += 1
	sorted_frames_dict = sorted(frames_dict.items(), key = operator.itemgetter(1))
	longest_frame = sorted_frames_dict[-1][0].strip('-')
	#longest_frame = sorted_frames_dict.keys()[-1]
	return longest_frame

def write_longest_frame(frame, inputdir, filename):
	with open(os.path.join(inputdir, filename) + '.fasta', 'w') as f:
		f.write(frame)


def main(argv):
	inputdir = ''
	try:
		opts, args = getopt.getopt(argv, "hi:", ["input-dir="])
	except getopt.GetoptError:
		print ('Usage: python3 find_longest_frame.py --input-dir <inputdirectory>')
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print ('Usage: python3 find_longest_frame.py --input-dir <inputdirectory>')
		if opt in ("-i", "--input-dir"):
			inputdir = arg
	print ('Input directory is ', inputdir)
	
	for filename in os.listdir(inputdir):
		if '.frame' in filename:
			frames = find_frames(os.path.join(inputdir, filename))
			longest_frame = find_longest_frame(frames)
			gene_name = filename.split('.')[0].strip('_')
			write_longest_frame(longest_frame, inputdir ,gene_name)




if __name__ == "__main__":
	main(sys.argv[1:])



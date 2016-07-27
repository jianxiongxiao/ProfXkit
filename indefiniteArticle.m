function article=indefiniteArticle(phrase)
% A simple function that returns the indefinite articles "a" or "an" based on a given word or phrase.
% based on the javascript implementation: https://github.com/rigoneri/indefinite-article.js/blob/master/indefinite-article.js
% indefiniteArticle('')
% indefiniteArticle('apple pie')
% indefiniteArticle('vision group')
% indefiniteArticle('Priceton local restaurant')

   % Getting the first word     
    [~,match] = regexp(phrase,'\w+');
    
    if ~isempty(match)
        word = phrase(1:match(1));
    else
        article=''; return;
    end
    
    l_word = lower(word);
    % Specific start of words that should be preceeded by 'an'
    alt_cases = {'honest', 'hour', 'hono'};
    for i=1:length(alt_cases)
        t = strfind(l_word, alt_cases{i});
        if (~isempty(t) && t(1) == 1)
            article='an'; return;
        end
    end
    
    % Single letter word which should be preceeded by 'an'
    if length(l_word) == 1
        if ~isempty(strfind('aedhilmnorsx',l_word))
            article='an'; return;
        else
            article='a'; return;
        end
    end
    
    % Capital words which should likely be preceeded by 'an'
    
    match = regexp(word,'(?!FJO|[HLMNS]Y.|RY[EO]|SQU|(F[LR]?|[HL]|MN?|N|RH?|S[CHKLMNPTVW]?|X(YL)?)[AEIOU])[FHLMNRSX][A-Z]', 'once');
    if ~isempty(match)
        article='an'; return;
    end
    
    % Special cases where a word that begins with a vowel should be preceeded by 'a'
    regexes = {'^e[uw]', '^onc?e\b', '^uni([^nmd]|mo)', '^u[bcfhjkqrst][aeiou]'};
    for i=1:length(regexes)
        match = regexp(l_word,regexes{i}, 'once');
        if ~isempty(match)
            article='a'; return;
        end
    end
    
    % Special capital words (UK, UN)
    match = regexp(word,'^U[NK][AIEO]', 'once');
    if ~isempty(match)
        article='a'; return;
    else
        if strcmp(word, upper(word))
            if ~isempty(strfind('aedhilmnorsx',l_word(1)))
                article='an'; return;
            else 
                article='a'; return;
            end
        end
    end
    
    % Basic method of words that begin with a vowel being preceeded by 'an'
    if ~isempty(strfind('aeiou',l_word(1)))
        article='an'; return;
    end
    
    % Instances where y follwed by specific letters is preceeded by 'an'
    match = regexp(l_word,'^y(b[lor]|cl[ea]|fere|gg|p[ios]|rou|tt)', 'once');
    if ~isempty(match)
        article='an'; return;
    end
    
    article='a'; return;
    